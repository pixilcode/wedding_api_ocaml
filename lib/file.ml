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
  Out_channel.with_file path ~f:(fun file ->
    Out_channel.output_string file contents
  )

let create_dir ?(permissions=0o755) path =
  Lwt.catch
    (fun () -> Lwt_unix.mkdir path permissions)
    (function
      | Core_unix.Unix_error (Core_unix.EEXIST, _, _) -> Lwt.return_unit
      | e -> Lwt.fail e
    )

let read_file path =
  In_channel.with_file path ~f:(fun file ->
    let contents = In_channel.input_all file in
    contents
  )

let write_to_file ?(append=true) path contents =
  Out_channel.with_file ~append path ~f:(fun file ->
    Out_channel.output_string file contents
  )
