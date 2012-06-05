(* ocamlgsl - OCaml interface to GSL                        *)
(* Copyright (©) 2007 - Olivier Andrieu                     *)
(* distributed under the terms of the GPL version 2         *)

(** Basis Splines *)

type ws

val make : k:int -> nbreak:int -> ws
external ncoeffs : ws -> int = "ml_gsl_bspline_ncoeffs" "noalloc"

open Gsl_vectmat

external knots : [< vec] -> ws -> unit = "ml_gsl_bspline_knots"
external knots_uniform : a:float -> b:float -> ws -> unit = "ml_gsl_bspline_knots_uniform"

external _eval : float -> [< vec] -> ws -> unit = "ml_gsl_bspline_eval"
val eval : ws -> float -> [> vec]