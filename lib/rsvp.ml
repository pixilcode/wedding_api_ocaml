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
    Lwt_io.with_file
      path
      ~mode:Lwt_io.output
      (fun file -> Lwt_io.write file "\"Name\",\"Guest Count\"\n")
  else
    Lwt.return ()

let append_to_rsvp_file csv_path contents: unit =
  (* TODO: figure out how to append to a file with `Lwt_io.with_file` *)
  Out_channel.with_file
    csv_path
    ~append:true
    ~f:(fun file -> Out_channel.output_string file contents)

let generate_file_name name =
  (* get the current time as a string *)
  let now = Time_float.now () in
  let zone = Time_float.Zone.of_utc_offset ~hours:(-6) in
  let now_string = Time_float.to_filename_string ~zone now in

  (* convert the name to a valid file name string *)
  (* TODO: verify if there's a better way to do this *)
  let non_alpha_dash_re = Re.compile Re.(diff any (alt [alpha; char '-'])) in
  let filtered_name =
    name
    |> String.lowercase
    |> String.substr_replace_all ~pattern:" " ~with_:"-"
    |> Re.replace_string non_alpha_dash_re ~by:""
  in

  (* combine the strings *)
  Printf.sprintf "%s-%s.txt" now_string filtered_name
  
let create_personal_rsvp_file path name guest_count =
  let file_name = generate_file_name name in
  let file_contents = Printf.sprintf "name=%s\nguest_count=%d\n" name guest_count in

  let file_path = path ^ "/" ^ file_name in

  Lwt_io.with_file
    file_path
    ~mode:Lwt_io.output
    (fun file -> Lwt_io.write file file_contents)

let add ~data_dir ~name ~guest_count =
  let Validate.Name name = name in
  let Validate.Guest_count guest_count = guest_count in

  let csv_path = data_dir ^ "/rsvp.csv" in
  let rsvp_dir = data_dir ^ "/rsvp" in

  let%lwt () = create_personal_rsvp_file rsvp_dir name guest_count in

  (* create the RSVP file and directory if they aren't already created *)
  let%lwt _ =
    Lwt.both
      (create_rsvp_file_if_not_exists csv_path)
      (File.create_dir rsvp_dir)
  in
  
  let contents = Printf.sprintf "\"%s\",%d\n" name guest_count in
  append_to_rsvp_file csv_path contents;

  Lwt.return_unit
