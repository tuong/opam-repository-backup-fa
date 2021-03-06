(******************************************************************************
 *                             Core-extended                                  *
 *                                                                            *
 * Copyright (C) 2008- Jane Street Holding, LLC                               *
 *    Contact: opensource@janestreet.com                                      *
 *    WWW: http://www.janestreet.com/ocaml                                    *
 *                                                                            *
 *                                                                            *
 * This library is free software; you can redistribute it and/or              *
 * modify it under the terms of the GNU Lesser General Public                 *
 * License as published by the Free Software Foundation; either               *
 * version 2 of the License, or (at your option) any later version.           *
 *                                                                            *
 * This library is distributed in the hope that it will be useful,            *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of             *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU          *
 * Lesser General Public License for more details.                            *
 *                                                                            *
 * You should have received a copy of the GNU Lesser General Public           *
 * License along with this library; if not, write to the Free Software        *
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA  *
 *                                                                            *
 ******************************************************************************)

(** A [t] represents a match statement where every case is documented.  You can then use it
    in one way to extract documentation, and in another way as the underlying function.

    More specifically, an [('input,'output) t] represents a match statement matching things
    of type [input'] and producing things of type ['output]. It consists of
    [specific_cases] and a [catchall_case].

    The [specific_cases] are straightforward:
    [{pattern=pattern;documentation=documentation;value=value}] represents
    "| pattern -> value", with [documentation] explaining what's going on.

    The [catchall_case] can be either [`Unused x], representing "| _ -> x" with no
    documentation, or [`Used case], representing "| x -> f x", where [f] is [case.value],
    and [case.documentation] explains what's going on with [f].  This is intended to allow
    many input values to be handled uniformly without having to document each one individually.
*)

type ('input,'output) case = {
  pattern : 'input list;
  documentation : string;
  value : 'output;
}

type ('input,'output) t = {
  specific_cases : ('input, unit -> 'output) case list;
  catchall_case :
    [ `Used of ([ `Catchall ], 'input -> 'output ) case
    | `Unused of unit -> 'output];
}

val map : ('input,'output1) t -> f:('output1 -> 'output2) -> ('input,'output2) t

val map_cases :
  ('input, unit -> 'output1) case list
  -> f:('output1 -> 'output2)
  -> ('input, unit -> 'output2) case list

val map_pattern : ('input1, 'output) t ->
  f1:('input1 -> 'input2) ->
  f2:('input2 -> 'input1) ->
  ('input2,'output) t

(** [prepend ~specific_cases t] matches on [specific_cases] before moving on to [t].

    A common situation is representing
    let f t x =
    match x with
    | `A -> ...
    | `B -> ...
    | _ -> {t with field = g t.field x}

    which can be done by combining [prepend] and [map]:
    let f' =
    prepend ~specific_cases:[{pattern = `A;...};{pattern = `B;...}]
    (map g' ~f:(fun h t -> {t with field = h t.field}))
*)
val prepend :
  specific_cases:('input, unit -> 'output) case list ->
  ('input,'output) t ->
  ('input,'output) t

(** [match_ t] pulls out the underlying function of [t]  *)
val match_ : ('input,'output) t -> 'input -> 'output

val documentation :
  ('input, 'output) t
  -> input_to_string:('input -> string)
  -> title:string
  -> string list
