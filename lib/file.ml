open Core

let prepend_datetime_to file_name =
  let now = Time_float.now () in
  (* TODO: make timezone adjustable, rather than just MST *)
  let zone = Time_float.Zone.of_utc_offset ~hours:(-6) in
  let now_string = Time_float.to_filename_string ~zone now in
  Printf.sprintf "%s-%s" now_string file_name

let extract_extension file_name =
  file_name
  |> String.rsplit2 ~on:'.'
  |> Option.map ~f:snd

let filename_string_of s =
  s
  |> String.substr_replace_all ~pattern:" " ~with_:"-"
  |> String.filter ~f:(fun c -> Char.is_alpha c || Char.equal c '-')
  |> String.lowercase

let create_file ?(contents="") path =
  Lwt_io.with_file
    path
    ~mode:Lwt_io.output
    ~flags:[Core_unix.O_CREAT; Core_unix.O_WRONLY; Core_unix.O_TRUNC]
    (fun file -> Lwt_io.write file contents)

let create_dir ?(permissions=0o755) path =
  Lwt.catch
    (fun () -> Lwt_unix.mkdir path permissions)
    (function
      | Core_unix.Unix_error (Core_unix.EEXIST, _, _) -> Lwt.return_unit
      | e -> Lwt.fail e
    )

let read_file path =
  Lwt_io.with_file
    path
    ~mode:Lwt_io.input
    ~flags:[Core_unix.O_RDONLY]
    (fun file -> Lwt_io.read file)

let write_to_file ?(append=true) path contents =
  let append_flag_opt = if append then [Core_unix.O_APPEND] else [Core_unix.O_TRUNC] in
  let flags = List.append [Core_unix.O_WRONLY] append_flag_opt in
  Lwt_io.with_file
    path
    ~mode:Lwt_io.output
    ~flags
    (fun file -> Lwt_io.write file contents)
