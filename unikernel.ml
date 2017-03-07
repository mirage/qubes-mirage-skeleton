(* Copyright (C) 2016, Thomas Leonard
   See the README file for details. *)

open Lwt
open Qubes

let src = Logs.Src.create "unikernel" ~doc:"Main unikernel code"
module Log = (val Logs.src_log src : Logs.LOG)

(* Get the first IPv4 address from a list of addresses. *)
let rec first_v4 = function
  | [] -> None
  | x :: xs ->
    match Ipaddr.to_v4 x with
    | None -> first_v4 xs
    | Some ipv4 -> Some ipv4

module Main
    (DB : Qubes.S.DB)
    (Stack : Mirage_stack_lwt.V4)
    (Time : Mirage_time_lwt.S) = struct

  (* Initialise DNS resolver *)
  module Resolver = Dns_resolver_mirage.Make(Time)(Stack)

  let get_required qubesDB key =
    match DB.read qubesDB key with
    | None -> failwith (Printf.sprintf "Required QubesDB key %S not found" key)
    | Some v ->
      Log.info (fun f -> f "QubesDB %S = %S" key v);
      v

  let start qubesDB stack _time =
    Log.info (fun f -> f "Starting");
    (* Start qrexec agent and GUI agent in parallel *)
    let qrexec = RExec.connect ~domid:0 () in
    let gui = GUI.connect ~domid:0 () in
    (* Wait for clients to connect *)
    qrexec >>= fun qrexec ->
    let agent_listener = RExec.listen qrexec Command.handler in
    gui >>= fun gui ->
    Lwt.async (fun () -> GUI.listen gui);
    Lwt.async (fun () ->
      OS.Lifecycle.await_shutdown_request () >>= fun (`Poweroff | `Reboot) ->
      RExec.disconnect qrexec
    );
    let resolver = Resolver.create stack in
    let dns = get_required qubesDB "/qubes-primary-dns" |> Ipaddr.V4.of_string_exn in

    (* Test by downloading http://google.com *)
    let test_host = "google.com" in
    Log.info (fun f -> f "Resolving %S" test_host);
    Resolver.gethostbyname resolver ~server:dns test_host >>= fun addresses ->
    match first_v4 addresses with
    | None -> failwith "google.com didn't resolve!"
    | Some google ->
    Log.info (fun f -> f "%S has IPv4 address %a" test_host Ipaddr.V4.pp_hum google);
    let tcp = Stack.tcpv4 stack in
    let port = 80 in
    Log.info (fun f -> f "Opening TCP connection to %a:%d" Ipaddr.V4.pp_hum google port);
    Stack.TCPV4.create_connection tcp (google, port) >>= function
    | Error err -> failwith (Format.asprintf "Failed to connect to %a:%d:%a" Ipaddr.V4.pp_hum google port Stack.TCPV4.pp_error err)
    | Ok conn ->
    Log.info (fun f -> f "Connected!");
    Stack.TCPV4.write conn (Cstruct.of_string "GET / HTTP/1.0\r\n\r\n") >>= function
    | Error _ -> failwith "Failed to write HTTP request"
    | Ok () ->
    let rec read_all () =
      Stack.TCPV4.read conn >>= function
      | Ok (`Data d) -> Log.info (fun f -> f "Received %S" (Cstruct.to_string d)); read_all ()
      | Error _ -> failwith "Error reading from TCP stream"
      | Ok `Eof -> Lwt.return ()
    in
    read_all () >>= fun () ->
    Log.info (fun f -> f "Closing TCP connection");
    Stack.TCPV4.close conn >>= fun () ->
    Log.info (fun f -> f "Network test done. Waiting for qrexec commands...");
    agent_listener
end
