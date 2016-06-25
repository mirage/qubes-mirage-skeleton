open Mirage

let main =
  foreign
    ~libraries:["mirage-qubes"; "dns.mirage"]
    ~packages:["mirage-qubes"; "dns"]
    "Unikernel.Main" (stackv4 @-> job)

(* These are dummy values; we'll read the real settings from QubesDB at start-up *)
let ip_config = {
  address = Ipaddr.V4.of_string_exn "127.0.0.1";
  netmask = Ipaddr.V4.of_string_exn "255.255.255.255";
  gateways = [];
}

let stack = direct_stackv4_with_static_ipv4
    default_console
    (netif "0")
    ip_config

let () =
  register "qubes-skeleton" ~argv:no_argv [main $ stack]
