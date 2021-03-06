open! Import

let test_gtkwave () =
  let module G = Cyclesim.With_interface (Fir_filter.I) (Fir_filter.O) in
  let module S = Cyclesim in
  let module Gtkwave = Vcd.Gtkwave in
  let sim = G.create ~kind:Immutable
              (Fir_filter.f (List.map ~f:(Signal.consti 16) [3; 5; 2; 1])) in
  let i = S.inputs sim in
  let sim = Gtkwave.gtkwave sim in
  let open Fir_filter.I in
  S.reset sim;
  i.enable := Bits.vdd;
  i.d :=  Bits.consti 16 1;    S.cycle sim;
  i.d :=  Bits.consti 16 3;    S.cycle sim;
  i.d :=  Bits.consti 16 (-2); S.cycle sim;
  i.d :=  Bits.consti 16 4;    S.cycle sim; S.cycle sim;
  In_channel.input_line In_channel.stdin |> ignore

let () = test_gtkwave ()
