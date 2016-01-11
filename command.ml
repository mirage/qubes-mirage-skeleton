open Lwt

module Flow = Qubes.RExec.Flow

let src = Logs.Src.create "command" ~doc:"qrexec command handler"
module Log = (val Logs.src_log src : Logs.LOG)

let echo ~user flow =
  Flow.writef flow "Hi %s! Please enter a string:" user >>= fun () ->
  Flow.read_line flow >>= function
  | `Eof -> return 1
  | `Ok input ->
  Flow.writef flow "You wrote %S. Bye." input >|= fun () -> 0

let handler ~user cmd flow =
  (* Write a message to the client and return an exit status of 1. *)
  let error fmt =
    fmt |> Printf.ksprintf @@ fun s ->
    Log.warn (fun f -> f "<< %s" s);
    Flow.ewritef flow "%s [while processing %S]" s cmd >|= fun () -> 1 in
  match cmd with
  | "echo" -> echo ~user flow
  | cmd -> error "Unknown command %S" cmd
