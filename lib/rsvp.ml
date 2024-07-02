open Core

let create_rsvp_file_if_not_exists path =
  let%lwt exists = Lwt_unix.file_exists path in
  if not exists then
    Lwt_io.with_file
      path
      ~mode:Lwt_io.output
      (fun file -> Lwt_io.write file "\"Name\",\"Guest Count\"\n")
  else
    Lwt.return ()

let add ~path ~name ~guest_count =
  let%lwt () = create_rsvp_file_if_not_exists path in
  let contents = Printf.sprintf "\"%s\",%d\n" name guest_count in
  (* TODO: figure out how to append to a file with `Lwt_io.with_file` *)
  Out_channel.with_file
    path
    ~append:true
    ~f:(fun file -> Out_channel.output_string file contents);
  Lwt.return_unit
