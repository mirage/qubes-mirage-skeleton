open Mirage

let main =
  foreign
    ~libraries:["mirage-qubes"]
    ~packages:["mirage-qubes"]
    "Unikernel.Main" (console @-> clock @-> job)

let () =
  register "qubes-skeleton" [main $ default_console $ default_clock]
