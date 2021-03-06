(* This file was automatically generated by z_pp.pl from z.mlp *)  (**
   Integers.


   This file is part of the Zarith library 
   http://forge.ocamlcore.org/projects/zarith .
   It is distributed under LGPL 2 licensing, with static linking exception.
   See the LICENSE file included in the distribution.
   
   Copyright (c) 2010-2011 Antoine Miné, Abstraction project.
   Abstraction is part of the LIENS (Laboratoire d'Informatique de l'ENS),
   a joint laboratory by:
   CNRS (Centre national de la recherche scientifique, France),
   ENS (École normale supérieure, Paris, France),
   INRIA Rocquencourt (Institut national de recherche en informatique, France).

 *)

type t

exception Overflow

external init: unit -> unit = "ml_z_init"
let _ = init ()

external install_frametable: unit -> unit = "ml_z_install_frametable"
let _ =  install_frametable ()

let _ = Callback.register_exception "ml_z_overflow" Overflow

external neg: t -> t = "ml_z_neg" "ml_as_z_neg"
external add: t -> t -> t = "ml_z_add" "ml_as_z_add"
external sub: t -> t -> t = "ml_z_sub" "ml_as_z_sub"
external mul: t -> t -> t = "ml_z_mul" "ml_as_z_mul"
external div: t -> t -> t = "ml_z_div" "ml_as_z_div"
external cdiv: t -> t -> t = "ml_z_cdiv"
external fdiv: t -> t -> t = "ml_z_fdiv"
external rem: t -> t -> t = "ml_z_rem" "ml_as_z_rem"
external div_rem: t -> t -> (t * t) = "ml_z_div_rem"
external succ: t -> t = "ml_z_succ" "ml_as_z_succ"
external pred: t -> t = "ml_z_pred" "ml_as_z_pred"
external abs: t -> t = "ml_z_abs" "ml_as_z_abs"
external logand: t -> t -> t = "ml_z_logand" "ml_as_z_logand"
external logor: t -> t -> t = "ml_z_logor" "ml_as_z_logor"
external logxor: t -> t -> t = "ml_z_logxor" "ml_as_z_logxor"
external lognot: t -> t = "ml_z_lognot" "ml_as_z_lognot"
external shift_left: t -> int -> t = "ml_z_shift_left" "ml_as_z_shift_left"
external shift_right: t -> int -> t = "ml_z_shift_right" "ml_as_z_shift_right"
external shift_right_trunc: t -> int -> t = "ml_z_shift_right_trunc"
external of_int32: int32 -> t = "ml_z_of_int32"
external of_int64: int64 -> t = "ml_z_of_int64"
external of_nativeint: nativeint -> t = "ml_z_of_nativeint"
external of_float: float -> t = "ml_z_of_float"
external to_int: t -> int = "ml_z_to_int"
external to_int32: t -> int32 = "ml_z_to_int32"
external to_int64: t -> int64 = "ml_z_to_int64"
external to_nativeint: t -> nativeint = "ml_z_to_nativeint"
external to_float: t -> float = "ml_z_to_float"
external format: string -> t -> string = "ml_z_format"
external of_string_base: int -> string -> t = "ml_z_of_string_base"
external compare: t -> t -> int = "ml_z_compare" "noalloc"
external equal: t -> t -> bool = "ml_z_equal" "noalloc"
external sign: t -> int = "ml_z_sign" "noalloc"
external gcd: t -> t -> t = "ml_z_gcd"
external gcdext_intern: t -> t -> (t * t * bool) = "ml_z_gcdext_intern"
external sqrt: t -> t = "ml_z_sqrt"
external sqrt_rem: t -> (t * t) = "ml_z_sqrt_rem"
external popcount: t -> int = "ml_z_popcount"
external hamdist: t -> t -> int = "ml_z_hamdist"
external size: t -> int = "ml_z_size" "noalloc"
external fits_int: t -> bool = "ml_z_fits_int" "noalloc"
external fits_int32: t -> bool = "ml_z_fits_int32" "noalloc"
external fits_int64: t -> bool = "ml_z_fits_int64" "noalloc"
external fits_nativeint: t -> bool = "ml_z_fits_nativeint" "noalloc"
external extract: t -> int -> int -> t = "ml_z_extract"
external powm: t -> t -> t -> t = "ml_z_powm"
external pow: t -> int -> t = "ml_z_pow"
external divexact: t -> t -> t = "ml_z_divexact"
external root: t -> int -> t = "ml_z_root"
external invert: t -> t -> t = "ml_z_invert"
external perfect_power: t -> bool = "ml_z_perfect_power"
external perfect_square: t -> bool = "ml_z_perfect_square"
external probab_prime: t -> int -> int = "ml_z_probab_prime"
external nextprime: t -> t = "ml_z_nextprime"
external hash: t -> int = "ml_z_hash"
external to_bits: t -> string = "ml_z_to_bits"
external of_bits: string -> t = "ml_z_of_bits"

external of_int: int -> t = "%identity" (* it's magic... *)

let zero = of_int 0
let one = of_int 1
let minus_one = of_int (-1)

let min a b = if compare a b <= 0 then a else b
let max a b = if compare a b >= 0 then a else b

let leq a b = compare a b <= 0
let geq a b = compare a b >= 0
let lt a b = compare a b < 0
let gt a b = compare a b > 0

let to_string = format "%d"
let of_string = of_string_base 0

let ediv_rem a b =
  (* we have a = a * b + r, but [Big_int]'s remainder satisfies 0 <= r < |b|,
     while [Z]'s remainder satisfies -|b| < r < |b| and sign(r) = sign(a)
   *)
   let q,r = div_rem a b in
   if sign r >= 0 then (q,r) else
   if sign b >= 0 then (pred q, add r b)
   else (succ q, sub r b)

let ediv a b =
   if sign b >= 0 then fdiv a b else cdiv a b

let erem a b =
   let r = rem a b in
   if sign r >= 0 then r else add r (abs b)

let gcdext u v =
  let g,s,z = gcdext_intern u v in
  if z then g, s, div (sub g (mul u s)) v
  else g, div (sub g (mul v s)) u, s

let lcm u v = 
  let g = gcd u v in
  abs (mul (divexact u g) v)

let signed_extract x o l =
  if o < 0 then invalid_arg "Z.signed_extract: negative bit offset";
  if l < 1 then invalid_arg "Z.signed_extract: non-positive bit length";
  let sgn = extract x (o + l - 1) 1 in
  if equal sgn (of_int 0)
  then extract x o l
  else lognot (extract (lognot x) o l)

let print x = print_string (to_string x)
let output chan x = output_string chan (to_string x)
let sprint () x = to_string x
let bprint b x = Buffer.add_string b (to_string x)
let pp_print f x = Format.pp_print_string f (to_string x)

external (~-): t -> t = "ml_z_neg" "ml_as_z_neg"
external (~+): t -> t = "%identity"
external (+): t -> t -> t = "ml_z_add" "ml_as_z_add"
external (-): t -> t -> t = "ml_z_sub" "ml_as_z_sub"
external ( * ): t -> t -> t = "ml_z_mul" "ml_as_z_mul"
external (/): t -> t -> t = "ml_z_div" "ml_as_z_div"
external (/>): t -> t -> t = "ml_z_cdiv"
external (/<): t -> t -> t = "ml_z_fdiv"
external (/|): t -> t -> t = "ml_z_divexact"
external (mod): t -> t -> t = "ml_z_rem" "ml_as_z_rem"
external (land): t -> t -> t = "ml_z_logand" "ml_as_z_logand"
external (lor): t -> t -> t = "ml_z_logor" "ml_as_z_logor"
external (lxor): t -> t -> t = "ml_z_logxor" "ml_as_z_logxor"
external (~!): t -> t = "ml_z_lognot" "ml_as_z_lognot"
external (lsl): t -> int -> t = "ml_z_shift_left" "ml_as_z_shift_left"
external (asr): t -> int -> t = "ml_z_shift_right" "ml_as_z_shift_right"
external (~$): int -> t = "%identity" 
external ( ** ): t -> int -> t = "ml_z_pow"

