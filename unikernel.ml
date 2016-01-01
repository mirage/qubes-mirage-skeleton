(* Copyright (C) 2015, Thomas Leonard
   See the README file for details. *)

open Lwt
open Qubes

let src = Logs.Src.create "unikernel" ~doc:"Main unikernel code"
module Log = (val Logs.src_log src : Logs.LOG)

let () = Logs.set_level (Some Logs.Info)

module Main (Clock : V1.CLOCK) = struct
  module Log_reporter = Mirage_logs.Make(Clock)
  let log_buf = Buffer.create 100
  let log_fmt = Format.formatter_of_buffer log_buf

  let wait_for_shutdown () =
    OS.Xs.make () >>= fun xs ->
    OS.Xs.wait xs (fun xsh ->
      OS.Xs.read xsh ("control/shutdown") >>= function
      | "poweroff" -> return `Poweroff
      | "" -> fail Xs_protocol.Eagain
      | state ->
          Log.info "Unknown power state %S" (fun f -> f state);
          fail Xs_protocol.Eagain
    )

  let start () =
    let start_time = Clock.time () in
    Log_reporter.init_logging ();
    (* Start qrexec agent, GUI agent and QubesDB agent in parallel *)
    let qrexec = RExec.connect ~domid:0 () in
    let gui = GUI.connect ~domid:0 () in
    let qubesDB = DB.connect ~domid:0 () in
    (* Wait for clients to connect *)
    qrexec >>= fun qrexec ->
    let agent_listener = RExec.listen qrexec Command.handler in
    gui >>= fun gui ->
    Lwt.async (fun () -> GUI.listen gui);
    qubesDB >>= fun qubesDB ->
    Log.info "agents connected in %.3f s (CPU time used since boot: %.3f s)"
      (fun f -> f (Clock.time () -. start_time) (Sys.time ()));
    begin match DB.read qubesDB "/qubes-ip" with
    | None -> Log.info "No IP address assigned" Logs.unit
    | Some ip -> Log.info "My IP address is %S" (fun f -> f ip) end;
    Lwt.async (fun () ->
      wait_for_shutdown () >>= fun `Poweroff ->
      RExec.disconnect qrexec
    );
    agent_listener
end
