open Mirage

let main =
  let packages = [
    package "mirage-qubes";
    package "dns";
    package "dns-client" ~sublibs:["mirage"] ~min:"4.5.0";
  ] in
  foreign
    ~packages
    "Unikernel.Main" (random @-> qubesdb @-> stackv4 @-> time @-> mclock @-> job)

let stack = qubes_ipv4_stack default_network

let () =
  register "qubes-skeleton" ~argv:no_argv [
    main $ default_random $ default_qubesdb $ stack $ default_time $ default_monotonic_clock
  ]
