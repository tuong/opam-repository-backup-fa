#!/usr/bin/ocamlrun ocaml

(******************************************************************************)
(* OASIS: architecture for building OCaml libraries and applications          *)
(*                                                                            *)
(* Copyright (C) 2008-2010, OCamlCore SARL                                    *)
(*                                                                            *)
(* This library is free software; you can redistribute it and/or modify it    *)
(* under the terms of the GNU Lesser General Public License as published by   *)
(* the Free Software Foundation; either version 2.1 of the License, or (at    *)
(* your option) any later version, with the OCaml static compilation          *)
(* exception.                                                                 *)
(*                                                                            *)
(* This library is distributed in the hope that it will be useful, but        *)
(* WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY *)
(* or FITNESS FOR A PARTICULAR PURPOSE. See the file COPYING for more         *)
(* details.                                                                   *)
(*                                                                            *)
(* You should have received a copy of the GNU Lesser General Public License   *)
(* along with this library; if not, write to the Free Software Foundation,    *)
(* Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA              *)
(******************************************************************************)

#use "topfind";;
#require "oasis";;
#require "oasis.base";;
#require "pcre";;
#require "fileutils";;

open OASISMessage
open OASISTypes
open OASISUtils
open FileUtil

let with_tmpdir f = 
  let res =
    Filename.temp_file "oasis-dist-" ".dir"
  in
  let clean () = 
(*     rm ~recurse:true [res] *)
    let _i : int = 
      Sys.command (Printf.sprintf "rm -rf %s" (Filename.quote res))
    in
      ()
  in
    Sys.remove res; 
    FileUtil.mkdir res; 
    try 
      f res;
      clean ()
    with e ->
      clean ();
      raise e

let update_oasis_in_tarball fn topdir = 
  with_tmpdir
    (fun dn ->
       BaseExec.run "tar" ["-C"; dn; "-xzf"; fn];
       BaseExec.run "oasis" ["-C"; Filename.concat dn topdir; "setup"];
       BaseExec.run "tar" ["-C"; dn; "-czf"; fn; topdir])

class virtual vcs = 
object
  method check_uncommited_changes = 
    true

  method list_tags : string list =
    []

  method virtual dist : string -> host_filename -> unit

  method virtual tag : string -> unit
end

class svn ~ctxt =
object 
  inherit vcs

  method check_uncommited_changes =
    match BaseExec.run_read_output "svn" ["status"] with
      | [] ->
          true
      | lst ->
          false

  method dist topdir tarball = 
    with_tmpdir 
      (fun dir ->
         let tgt = 
           Filename.concat dir topdir
         in
         let cur_pwd = 
           pwd ()
         in
           BaseExec.run "svn" ["export"; cur_pwd; tgt];
           BaseExec.run "tar" ["-C"; dir; "-czf"; tarball; topdir])

  method tag ver =
    warning ~ctxt "No tag method"
end

(* TODO: check file permissions +x for darcs *)
class darcs ~ctxt = 
object
  inherit vcs

  val ctxt = ctxt

  method check_uncommited_changes = 
    let ok = 
      ref false
    in
      (* Check that everything is commited *)
      BaseExec.run 
        ~f_exit_code:
        (function 
           | 1 -> 
               ok := true
           | 0 ->
               ()
           | n ->
               failwithf
                 "Unexpected exit code %d" n
        )
        "darcs" ["whatsnew"; "-ls"];
      !ok

  method list_tags = 
    BaseExec.run_read_output "darcs" ["show"; "tags"]

  method dist topdir tarball = 
    (* Create the tarball *)
    BaseExec.run "darcs" ["dist"; "--dist-name"; topdir];
    mv (topdir^".tar.gz") tarball

  method tag ver = 
    BaseExec.run "darcs" ["tag"; ver]
end

class git ~ctxt =
object
  inherit vcs

  method check_uncommited_changes = 
    match BaseExec.run_read_output "git" ["status"; "--porcelain"] with 
      | [] -> 
          true
      | _ ->
          false

  method list_tags = 
    BaseExec.run_read_output "git" ["tag"]

  method dist topdir tarball = 
    let tarfn = 
      Filename.chop_extension tarball
    in
      BaseExec.run 
        "git" 
        ["archive"; "--prefix";  (Filename.concat topdir "");
         "--format"; "tar"; "HEAD"; "-o"; tarfn];
      BaseExec.run "gzip" [tarfn]

  method tag ver =
    BaseExec.run "git" ["tag"; ver]
end

class no_vcs ~ctxt =
object 
  inherit vcs

  val ctxt = ctxt

  method dist topdir tarball = 
    with_tmpdir 
      (fun dir ->
         let tgt = 
           Filename.concat dir topdir
         in
         let cur_pwd = 
           pwd ()
         in
           BaseExec.run "cp" ["-r"; cur_pwd; tgt];
           begin
             try 
               Sys.chdir tgt;
               BaseExec.run "ocaml" ["setup.ml"; "-distclean"];
               Sys.chdir dir;
               BaseExec.run "tar" ["czf"; tarball; topdir];
               Sys.chdir cur_pwd;
             with e ->
               Sys.chdir cur_pwd;
               raise e
           end)

  method tag ver =
    warning ~ctxt "No tag method"
end

let () = 
  let ctxt = 
    {!OASISContext.default with 
         OASISContext.ignore_plugins = true}
  in
  let pkg = 
    OASISParse.from_file
      ~ctxt
      "_oasis"
  in

  let topdir = 
    pkg.name^"-"^(OASISVersion.string_of_version pkg.version)
  in

  let tarball = 
    Filename.concat (pwd ()) (topdir^".tar.gz")
  in

  let vcs = 
    let test_dir dn () = 
      test Is_dir dn
    in
      try 
        snd
          (List.find 
             (fun (f, res) -> f ())
             [
               test_dir "_darcs", new darcs ctxt;
               test_dir ".git",   new git ctxt;
               test_dir ".svn",   new svn ctxt;
             ])
      with Not_found ->
        new no_vcs ctxt
  in

    if not vcs#check_uncommited_changes then
      begin
        error ~ctxt "Uncommited changes";
        exit 1
      end;

    (* Create the tarball *)
    vcs#dist topdir tarball;

    (* Run "oasis setup" *)
    update_oasis_in_tarball tarball topdir;

    (* Check that the tarball can build *)
    with_tmpdir 
      (fun dir -> 
         let pwd =
           FileUtil.pwd ()
         in
           (* Uncompress tarball in tmpdir *)
           BaseExec.run "tar" ["xz"; "-C"; dir; "-f"; tarball];

           Sys.chdir dir;
           Sys.chdir topdir;

           try 
             let () = 
               if Sys.file_exists "setup.data" then
                 failwith
                   "Remaining setup.data file."
             in

             let () = 
               (* Check that build, test, doc run smoothly *)
               BaseExec.run "ocaml" ["setup.ml"; "-all"]
             in

             let () = 
               let bak_files = 
                 (* Check for remaining .bak files *)
                 find (Has_extension "bak") 
                   FilePath.current_dir
                   (fun acc fn -> fn :: acc)
                   []
               in
                 if bak_files <> [] then
                   failwithf
                     "Remaining .bak files: %s."
                     (String.concat ", " bak_files)
             in

               Sys.chdir pwd

           with e ->
             Sys.chdir pwd;
             raise e);

    begin
      let tags = 
        List.sort 
          OASISVersion.version_compare 
          (List.rev_map
             OASISVersion.version_of_string 
             vcs#list_tags)
      in
      let ver_str =
        OASISVersion.string_of_version pkg.version
      in
        match tags with
          | hd :: _ ->
              begin
                let cmp = 
                  OASISVersion.version_compare hd pkg.version
                in
                  if List.mem pkg.version tags then
                    begin
                      warning ~ctxt "Version %s already tagged" ver_str
                    end
                  else if cmp > 0 then
                    begin
                      warning ~ctxt "Version %s is smaller than already tagged version %s" 
                        ver_str (OASISVersion.string_of_version hd);
                      vcs#tag ver_str
                    end
                  else
                    begin
                      vcs#tag ver_str
                    end
              end
          | _ ->
              vcs#tag ver_str
    end;
    
    BaseExec.run 
      ~f_exit_code:
      (fun i -> 
         if i <> 0 then
           warning ~ctxt "Cannot sign '%s' with gpg" tarball
         else
           ())
      "gpg" ["-s"; "-a"; "-b"; tarball]
