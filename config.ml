open Mirage

let main =
  let packages = [package "mirage-qubes"; package "dns" ~sublibs:["mirage"]; package "tcpip" ~sublibs:["ethif"; "arpv4"; "ipv4"; "icmpv4"; "udp"; "tcp"; "stack-direct"]] in
  foreign
    ~packages
    "Unikernel.Main" (random @-> time @-> mclock @-> network @-> ethernet @-> arpv4 @-> job)

 let net = default_network

 let eth = etif net

 let arp = arp eth

let () =
  register "qubes-skeleton" ~argv:no_argv [main $ default_random $ default_time $ default_monotonic_clock $ net $ eth $ arp]
