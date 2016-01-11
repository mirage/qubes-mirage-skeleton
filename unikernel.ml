(* Copyright (C) 2015, Thomas Leonard
   See the README file for details. *)

open Lwt
open Qubes

let src = Logs.Src.create "unikernel" ~doc:"Main unikernel code"
module Log = (val Logs.src_log src : Logs.LOG)

module Main = struct
  let start =
    Log.info (fun f -> f "start");
    let start_time = Clock.time () in
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
    Log.info (fun f ->
      f "agents connected in %.3f s (CPU time used since boot: %.3f s)"
        (Clock.time () -. start_time) (Sys.time ()));
    begin match DB.read qubesDB "/qubes-ip" with
    | None -> Log.info (fun f -> f "No IP address assigned")
    | Some ip -> Log.info (fun f -> f "My IP address is %S" ip) end;
    Lwt.async (fun () ->
      OS.Lifecycle.await_shutdown_request () >>= fun (`Poweroff | `Reboot) ->
      RExec.disconnect qrexec
    );
    agent_listener
end
