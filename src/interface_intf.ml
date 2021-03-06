(** Interfaces specify the widths and names of a group of signals, and some functions for
    manipulating the signals as a group.

    They are generally used with [ppx_deriving_hardcaml] as follows

    {[
      type t = { ... } [@@deriving sexp_of, hardcaml]
    ]}

    The [sexp_of] is required, and must appear before [hardcaml].  This syntax
    generates a call to [Interface.Make], which therefore does not need to be
    explicitly called. *)

open! Import

module type Pre = sig
  type 'a t
  [@@deriving sexp_of]

  val t : (string * int) t
  val iter : f:('a -> unit) -> 'a t -> unit
  val iter2 : f:('a -> 'b -> unit) -> 'a t -> 'b t -> unit
  val map : f:('a -> 'b) -> 'a t -> 'b t
  val map2 : f:('a -> 'b -> 'c) -> 'a t -> 'b t -> 'c t
  val to_list : 'a t -> 'a list
end

module type Comb = sig

  type 'a interface
  type comb

  type t = comb interface [@@deriving sexp_of]

  (** Actual bit widths of each field. *)
  val widths : t -> int interface

  (** Each field is set to the constant integer value provided. *)
  val const : int -> t

  (** [consts c] sets each field to the integer value in [c] using the declared field bit
      width. *)
  val consts : int interface -> t

  (** Pack interface into a vector. *)
  val pack : ?rev:bool -> t -> comb

  (** Unpack interface from a vector. *)
  val unpack : ?rev:bool -> comb -> t

  (** Multiplex a list of interfaces. *)
  val mux : comb -> t list -> t

  val mux2 : comb -> t -> t -> t

  (** Concatenate a list of interfaces. *)
  val concat : t list -> t
end

module type S = sig

  include Pre

  include Equal.S1 with type 'a t := 'a t

  (** RTL names specified in the interface definition - commonly also the OCaml field
      name. *)
  val port_names : string t

  (** Bit widths specified in the interface definition. *)
  val port_widths : int t

  (** Create association list indexed by field names. *)
  val to_alist : 'a t -> (string * 'a) list

  (** Create interface from association list indexed by field names *)
  val of_alist : (string * 'a) list -> 'a t

  val zip  : 'a t -> 'b t -> ('a * 'b) t
  val zip3 : 'a t -> 'b t -> 'c t -> ('a * 'b * 'c) t
  val zip4 : 'a t -> 'b t -> 'c t -> 'd t -> ('a * 'b * 'c * 'd) t
  val zip5 : 'a t -> 'b t -> 'c t -> 'd t -> 'e t -> ('a * 'b * 'c * 'd * 'e) t

  val map3
    :  'a t -> 'b t -> 'c t
    -> f:('a -> 'b -> 'c -> 'd)
    -> 'd t
  val map4
    :  'a t -> 'b t -> 'c t -> 'd t
    -> f:('a -> 'b -> 'c -> 'd -> 'e)
    -> 'e t
  val map5
    :  'a t -> 'b t -> 'c t -> 'd t -> 'e t
    -> f:('a -> 'b -> 'c -> 'd -> 'e -> 'f)
    -> 'f t

  val iter3
    :  'a t -> 'b t -> 'c t
    -> f:('a -> 'b -> 'c -> unit)
    -> unit
  val iter4
    :  'a t -> 'b t -> 'c t -> 'd t
    -> f:('a -> 'b -> 'c -> 'd -> unit)
    -> unit
  val iter5
    :  'a t -> 'b t -> 'c t -> 'd t -> 'e t
    -> f:('a -> 'b -> 'c -> 'd -> 'e -> unit)
    -> unit

  val fold
    :  'a t
    -> init : 'b
    -> f : ('b -> 'a -> 'b)
    -> 'b

  val fold2
    :  'a t
    -> 'b t
    -> init : 'c
    -> f : ('c -> 'a -> 'b -> 'c)
    -> 'c

  (** Offset of each field within the interface.  The first field is placed at the least
      significant bit, unless the [rev] argument is true. *)
  val offsets
    :  ?rev:bool (** default is [false]. *)
    -> unit
    -> int t

  (** Take a list of interfaces and produce a single interface where each field is a
      list. *)
  val of_interface_list : 'a t list -> 'a list t

  (** Create a list of interfaces from a single interface where each field is a list.
      Raises if all lists don't have the same length. *)
  val to_interface_list : 'a list t -> 'a t list

  module type Comb = Comb with type 'a interface := 'a t

  module Make_comb (Comb : Comb.S) : Comb with type comb = Comb.t

  module Of_bits : Comb with type comb = Bits.t

  module Of_signal : sig
    include Comb with type comb = Signal.t

    (** Create a wire for each field.  If [named] is true then wires are given the RTL field
        name.  If [from] is provided the wire is attached to each given field in [from]. *)
    val wires
      :  ?named:bool (** default is [false]. *)
      -> ?from:t (** No default *)
      -> unit
      -> t

    val assign  : t -> t -> unit
    val ( <== ) : t -> t -> unit

    (** [inputs t] is [wires () ~named:true]. *)
    val inputs  : unit -> t

    (** [outputs t] is [wires () ~from:t ~named:true]. *)
    val outputs : t -> t
  end
end

module type Empty = sig
  type 'a t = None
  include S with type 'a t := 'a t
end

module type Interface = sig


  module type Pre = Pre
  module type S   = S

  module type Empty = Empty

  module Empty : Empty

  (** Type of functions representing the implementation of a circuit from an input to
      output interface. *)
  module Create_fn (I : S) (O : S) : sig
    type 'a t = 'a I.t -> 'a O.t [@@deriving sexp_of]
  end

  module Make (X : Pre) : S with type 'a t := 'a X.t
end
