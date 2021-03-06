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

(* An int of exactly 32 bits, regardless of the machine.

   Side note: There's not much reason to want an int of at least 32 bits (i.e.
   32 on 32-bit machines and 63 on 64-bit machines) because Int63 is basically
   just as efficient.
*)

include Int_intf.S with type t = int32

val bits_of_float : float -> t
val float_of_bits : t -> float

val of_int : int -> t option
val to_int : t -> int option
val of_int32 : int32 -> t
val to_int32 : t -> int32
val of_int64 : int64 -> t option
val of_nativeint : nativeint -> t option
val to_nativeint : t -> nativeint
