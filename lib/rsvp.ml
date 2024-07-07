open Core

module Validate = struct
  type validated_name = Name of string
  type validated_guest_count = Guest_count of int

  let name name =
    if String.length name < 1 then
      Error "Name must be at least 1 character"
    else
      let scrubbed_name = String.substr_replace_all ~pattern:"\"" ~with_:"''" name in
      Ok (Name scrubbed_name)

  let guest_count guest_count =
    match Int.of_string_opt guest_count with
    | Some guest_count ->
      if guest_count <= 0 then
        Error "Guest count must be a positive integer"
      else if guest_count > 30 then
        Error "Guest count must be 30 or fewer"
      else
        Ok (Guest_count guest_count)
    | None -> Error "Guest count must be an integer"
end

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
  let Validate.Name name = name in
  let Validate.Guest_count guest_count = guest_count in
  let%lwt () = create_rsvp_file_if_not_exists path in
  let contents = Printf.sprintf "\"%s\",%d\n" name guest_count in
  (* TODO: figure out how to append to a file with `Lwt_io.with_file` *)
  Out_channel.with_file
    path
    ~append:true
    ~f:(fun file -> Out_channel.output_string file contents);
  Lwt.return_unit
