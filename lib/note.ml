open Core

module Validate = struct
  type validated_name = Validated_name of string
  type validated_note = Validated_note of string
  type validated_image = Validated_image of string

  (* TODO: make these more thorough *)
  let name name = Ok (Validated_name name)
  let note note = Ok (Validated_note note)
  let image image = Ok (Validated_image image)
end

let save_user_note ~data_dir ~name ~note ~image ~extension =
  let (Validate.Validated_name name) = name in
  let (Validate.Validated_note note) = note in
  let (Validate.Validated_image image) = image in

  (* ensure that the `notes` directory is created *)
  let%lwt () = File.create_dir (data_dir ^/ "notes") in

  (* get the request-specific note dir *)
  let note_dir = (
    let general_note_dir = data_dir ^/ "notes" in

    let user_note_dir_name =
      name
      |> File.Name.filename_string_of
      |> File.Name.prepend_datetime_to
    in
    general_note_dir ^/ user_note_dir_name
  ) in
  
  (* create the note dir and save the note and image to it *)
  let%lwt () = File.create_dir note_dir in
  let note_contents = "Name: " ^ name ^ "\n\n" ^ note in
  let extension =
    extension
    |> Option.map ~f:(fun ext -> "." ^ ext)
    |> Option.value ~default:"" in
  
  let note_path = note_dir ^/ "note.txt" in
  let image_path = note_dir ^/ "image" ^ extension in
  
  Dream.info (fun log -> log "Saving note to %s" note_path);
  Dream.info (fun log -> log "Saving image to %s" image_path);

  let%lwt ((), ()) =
    Lwt.both
      (File.create_file ~contents:note_contents note_path)
      (File.create_file ~contents:image image_path)
  in
  Lwt.return_unit