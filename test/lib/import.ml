include Base
include Expect_test_helpers_kernel
include Hardcaml

module Command = Core.Command
module Waves   = Hardcaml_waveterm_jane

let error_s       = Or_error.error_s
let force         = Lazy.force
let incr          = Int.incr
let print_endline = Stdio.print_endline
let print_string  = Caml.print_string
let printf        = Caml.Printf.printf
let try_with      = Or_error.try_with
