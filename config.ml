open Mirage

let main =
  foreign
    ~libraries:["mirage-qubes"]
    ~packages:["mirage-qubes"]
    "Unikernel.Main" job

let () =
  register "qubes-skeleton" ~argv:no_argv [main]
