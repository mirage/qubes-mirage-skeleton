(* Copyright (C) 2015, Thomas Leonard
   See the README file for details. *)

open Lwt

module Main (C: V1_LWT.CONSOLE) (Clock : V1.CLOCK) = struct
  let wait_for_shutdown (module Log : Qubes.S.LOG) =
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
          Log.info "Unknown power state %S" state;
          fail Xs_protocol.Eagain
    )

  let make_log ~reporter name =
    let module Log = struct
      let debug fmt = Printf.ksprintf ignore fmt
      let info fmt = Printf.ksprintf (reporter name "info") fmt
      let warn fmt = Printf.ksprintf (reporter name "WARN") fmt
    end in
    (module Log : Qubes.S.LOG)

  let start c () =
    let start_time = Clock.time () in
    (* Initialise logging *)
    let reporter src lvl msg =
      let now = Clock.time () |> Gmtime.gmtime |> Gmtime.to_string in
      Lwt.async (fun () -> C.log_s c (Printf.sprintf "%s: %s [%s] %s" now lvl src msg)) in
    let (module Log) = make_log ~reporter "main" in
    let (module RExec_log) = make_log ~reporter "qrexec-agent" in
    let (module GUI_log) = make_log ~reporter "gui-agent" in
    let (module DB_log) = make_log ~reporter "qubesDB" in
    let module RExec = Qubes.RExec.Make(RExec_log) in
    let module GUI = Qubes.GUI.Make(GUI_log) in
    let module DB = Qubes.DB.Make(DB_log) in
    (* Start qrexec agent, GUI agent and QubesDB agent in parallel *)
    let qrexec = RExec.connect ~domid:0 () in
    let gui = GUI.connect ~domid:0 () in
    let qubesDB = DB.connect ~domid:0 () in
    (* Wait for clients to connect *)
    qrexec >>= fun qrexec ->
    let module Cmd = Commands.Make(RExec_log)(RExec.Flow) in
    let agent_listener = RExec.listen qrexec Cmd.handler in
    gui >>= fun _gui ->
    qubesDB >>= fun qubesDB ->
    Log.info "agents connected in %.3f s (CPU time used since boot: %.3f s)"
      (Clock.time () -. start_time) (Sys.time ());
    begin match DB.read qubesDB "/qubes-ip" with
    | None -> Log.info "No IP address assigned"
    | Some ip -> Log.info "My IP address is %S" ip end;
    Lwt.async (fun () ->
      wait_for_shutdown (module Log) >>= fun `Poweroff ->
      RExec.disconnect qrexec
    );
    agent_listener
end
