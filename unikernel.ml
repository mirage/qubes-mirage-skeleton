(* Copyright (C) 2015, Thomas Leonard
   See the README file for details. *)

open Lwt
open Qubes

let src = Logs.Src.create "unikernel" ~doc:"Main unikernel code"
module Log = (val Logs.src_log src : Logs.LOG)

let () = Logs.set_level (Some Logs.Info)

module Main (C: V1_LWT.CONSOLE) (Clock : V1.CLOCK) = struct
  let log_buf = Buffer.create 100
  let log_fmt = Format.formatter_of_buffer log_buf

  let wait_for_shutdown () =
    let module Xs = OS.Xs in
    Xs.make () >>= fun xs ->
    Xs.immediate xs (fun h -> Xs.read h "domid") >>= fun domid ->
    let domid = int_of_string domid in
    Xs.immediate xs (fun h -> Xs.getdomainpath h domid) >>= fun domainpath ->
    Xs.wait xs (fun xsh ->
      Xs.read xsh (domainpath ^ "/control/shutdown") >>= function
      | "poweroff" -> return `Poweroff
      | "" -> fail Xs_protocol.Eagain
      | state ->
          Log.info "Unknown power state %S" (fun f -> f state);
          fail Xs_protocol.Eagain
    )

  let string_of_level =
    let open Logs in function
    | App -> "APP"
    | Error -> "ERR"
    | Warning -> "WRN"
    | Info -> "INF"
    | Debug -> "DBG"

  (* Report a log message on [c]. *)
  let init_logging c =
    let report src level k fmt msgf =
      let now = Clock.time () |> Gmtime.gmtime |> Gmtime.to_string in
      let lvl = string_of_level level in
      let k _ =
        let msg = Buffer.contents log_buf in
        Buffer.clear log_buf;
        Lwt.async (fun () -> C.log_s c msg);
        k () in
      msgf @@ fun ?header:_ ?tags:_ ->
      Format.kfprintf k log_fmt ("%s: %s [%s] " ^^ fmt) now lvl (Logs.Src.name src) in
    Logs.set_reporter { Logs.report }

  let start c () =
    let start_time = Clock.time () in
    init_logging c;
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
