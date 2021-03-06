(******************************************************************************
 *                             Core                                           *
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

(* A substring is a contiguous sequence of characters in a string.  We use a
   functor because we want substrings of [string] and [bigstring].
*)
open Std_internal
type bigstring = Bigstring.t


module Blit : sig
  type ('src, 'dst) t =
      src:'src -> src_pos:int -> dst:'dst -> dst_pos:int -> len:int -> unit

  val string_string : (string, string) t
  val bigstring_string : (bigstring, string) t
  val string_bigstring : (string, bigstring) t
  val bigstring_bigstring : (bigstring, bigstring) t
end = struct
  type ('src, 'dst) t =
      src:'src -> src_pos:int -> dst:'dst -> dst_pos:int -> len:int -> unit

  let string_string : (string, string) t = Core_string.blit

  let string_bigstring : (string, bigstring) t =
    Bigstring.blit_string_bigstring
  ;;

  let bigstring_bigstring : (bigstring, bigstring) t =
    Bigstring.blit
  ;;

  let bigstring_string : (bigstring, string) t =
    Bigstring.blit_bigstring_string
  ;;
end

module type Base = sig
  type t

  val create : int -> t
  val length : t -> int
  val blit : (t, t) Blit.t
  val blit_to_string : (t, string) Blit.t
  val blit_to_bigstring : (t, bigstring) Blit.t
  val blit_from_string : (string, t) Blit.t
  val blit_from_bigstring : (bigstring, t) Blit.t

  
  val of_bigstring : bigstring -> t
  val of_string : string -> t
end

module type S = Substring_intf.S

module F (Base : Base) : S with type base = Base.t = struct

  type base = Base.t

  type t = {
    base : Base.t;
    pos : int;
    len : int;
  }

  let invariant t =
    assert (0 <= t.pos);
    assert (0 <= t.len);
    assert (t.pos + t.len <= Base.length t.base);
  ;;

  let base t = t.base
  let pos t = t.pos
  let length t = t.len

  let create ?pos ?len base =
    let (pos, len) =
      Ordered_collection_common.get_pos_len_exn ?pos ?len
        ~length:(Base.length base)
    in
    { base = base; pos = pos; len = len; }
  ;;

  let drop_prefix t n =
    if n > t.len then
      failwith "Substring.drop_prefix"
    else {
      base = t.base;
      pos = t.pos + n;
      len = t.len - n;
    }
  ;;

  let drop_suffix t n =
    if n > t.len then
      failwith "Substring.drop_suffix"
    else {
      base = t.base;
      pos = t.pos;
      len = t.len - n;
    }
  ;;

  let prefix t n =
    if n > t.len then
      failwith "Substring.prefix"
    else {
      base = t.base;
      pos = t.pos;
      len = n;
    }
  ;;

  let suffix t n =
    if n > t.len then
      failwith "Substring.suffix"
    else {
      base = t.base;
      pos = t.pos + t.len - n;
      len = n;
    }
  ;;

  let blit_to blit =
    (); fun t ~dst ~dst_pos ->
      blit ~src:t.base ~src_pos:t.pos ~dst ~dst_pos ~len:t.len
  ;;
  let blit_to_string = blit_to Base.blit_to_string
  let blit_to_bigstring = blit_to Base.blit_to_bigstring
  let blit_base = blit_to Base.blit

  let blit_from ~name blit =
    (); fun t ~src ~src_pos ~len ->
      if len > t.len then
        failwithf "Substring.blit_from_%s len > substring length : %d > %d"
          name len t.len ();
      blit ~src ~src_pos ~dst:t.base ~dst_pos:t.pos ~len
  ;;
  let blit_from_string = blit_from ~name:"string" Base.blit_from_string
  let blit_from_bigstring = blit_from ~name:"bigstring" Base.blit_from_bigstring

  let of_base base = { base = base; pos = 0; len = Base.length base }

  let of_string x = of_base (Base.of_string x)

  let of_bigstring x = of_base (Base.of_bigstring x)

  let make create blit t =
    let dst = create t.len in
    blit ~src:t.base ~src_pos:t.pos ~dst ~dst_pos:0 ~len:t.len;
    dst
  ;;
  let to_string = make String.create Base.blit_to_string
  let to_bigstring = make Bigstring.create Base.blit_to_bigstring

  let concat_gen create_dst blit_dst ts =
    let len = List.fold ts ~init:0 ~f:(fun len t -> len + length t) in
    let dst = create_dst len in
    ignore (List.fold ts ~init:0
               ~f:(fun dst_pos t ->
                 blit_dst t ~dst ~dst_pos;
                 dst_pos + length t));
    dst
  ;;

  let concat ts = of_base (concat_gen Base.create blit_base ts)
  let concat_string ts = concat_gen String.create blit_to_string ts
  let concat_bigstring ts =  concat_gen Bigstring.create blit_to_bigstring ts
end
