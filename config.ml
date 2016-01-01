open Mirage

let main =
  foreign
    ~libraries:["mirage-qubes"]
    ~packages:["mirage-qubes"]
    "Unikernel.Main" (clock @-> job)

let () =
  register "qubes-skeleton" [main $ default_clock]
