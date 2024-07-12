open Core

module Validate = struct
  type validated_name = Name of string
  type validated_guest_count = Guest_count of int

  let name name =
    if String.length name < 1 then
      Error "Name must be at least 1 character"
    else
      let scrubbed_name = String.substr_replace_all ~pattern:"\"" ~with_:"''" name in
      let scrubbed_name = String.substr_replace_all ~pattern:"\n" ~with_:"\\n" scrubbed_name in
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
    let contents = "\"Name\",\"Guest Count\"\n" in
    File.create_file ~contents path
  else
    Lwt.return ()

let generate_file_name name =
  (* convert the name to a valid file name string *)
  let file_name = File.filename_string_of name in

  (* prepend the date time *)
  let file_name = File.prepend_datetime_to file_name in

  (* append the `txt` extension *)
  Printf.sprintf "%s.txt" file_name
  
let create_personal_rsvp_file path name guest_count =
  let file_name = generate_file_name name in
  let file_contents = Printf.sprintf "name=%s\nguest_count=%d\n" name guest_count in

  let file_path = path ^/ file_name in

  File.create_file ~contents:file_contents file_path

let add ~data_dir ~name ~guest_count =
  let Validate.Name name = name in
  let Validate.Guest_count guest_count = guest_count in

  let csv_path = data_dir ^/ "rsvp.csv" in
  let rsvp_dir = data_dir ^/ "rsvp" in

  (* create the RSVP file and directory if they aren't already created *)
  let%lwt ((), ()) =
    Lwt.both
      (create_rsvp_file_if_not_exists csv_path)
      (File.create_dir rsvp_dir)
  in
  
  let%lwt () = create_personal_rsvp_file rsvp_dir name guest_count in

  let contents = Printf.sprintf "\"%s\",%d\n" name guest_count in
  File.write_to_file ~append:true csv_path contents
