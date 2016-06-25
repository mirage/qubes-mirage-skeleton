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

module Main (Stack : V1_LWT.STACKV4 with type IPV4.prefix = Ipaddr.V4.t) = struct
  module Resolver = Dns_resolver_mirage.Make(OS.Time)(Stack)

  let get_required qubesDB key =
    match DB.read qubesDB key with
    | None -> failwith (Printf.sprintf "Required QubesDB key %S not found" key)
    | Some v ->
      Log.info (fun f -> f "QubesDB %S = %S" key v);
      v

  let start stack =
    Log.info (fun f -> f "Starting");
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
    Lwt.async (fun () ->
      OS.Lifecycle.await_shutdown_request () >>= fun (`Poweroff | `Reboot) ->
      RExec.disconnect qrexec
    );
    (* Initialise IP network device with settings from QubesDB *)
    let ip_addr = get_required qubesDB "/qubes-ip" |> Ipaddr.V4.of_string_exn in
    let netmask = get_required qubesDB "/qubes-netmask" |> Ipaddr.V4.of_string_exn in
    let gateway = get_required qubesDB "/qubes-gateway" |> Ipaddr.V4.of_string_exn in
    let ip = Stack.ipv4 stack in
    Stack.IPV4.set_ip ip ip_addr >>= fun () ->
    Stack.IPV4.set_ip_netmask ip netmask >>= fun () ->
    Stack.IPV4.set_ip_gateways ip [gateway] >>= fun () ->

    (* Initialise DNS resolver *)
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
    | `Error _ -> failwith (Format.asprintf "Failed to connect to %a:%d" Ipaddr.V4.pp_hum google port)
    | `Ok conn ->
    Log.info (fun f -> f "Connected!");
    Stack.TCPV4.write conn (Cstruct.of_string "GET / HTTP/1.0\r\n\r\n") >>= function
    | `Error _ | `Eof -> failwith "Failed to write HTTP request"
    | `Ok () ->
    let rec read_all () =
      Stack.TCPV4.read conn >>= function
      | `Ok data -> Log.info (fun f -> f "Received %S" (Cstruct.to_string data)); read_all ()
      | `Error _ -> failwith "Error reading from TCP stream"
      | `Eof -> Lwt.return ()
    in
    read_all () >>= fun () ->
    Log.info (fun f -> f "Closing TCP connection");
    Stack.TCPV4.close conn >>= fun () ->
    Log.info (fun f -> f "Network test done. Waiting for qrexec commands...");
    agent_listener
end
