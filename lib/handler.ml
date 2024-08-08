open Core
open Core.Result.Monad_infix

type config =
  { data_dir : string
  }

(** Join form_fields into a comma-separated list *)
let concat_form_fields form_fields =
    form_fields
    |> List.map ~f:fst
    |> List.map ~f:(Printf.sprintf "'%s'")
    |> String.concat ~sep:", "

(** Inform the user of invalid form fields *)
let invalid_form_fields request ~form_fields ~expected =
  Dream.error (fun log ->
    log ~request "incorrect form fields: %s" (concat_form_fields form_fields));
  let expected =
    expected
    |> List.map ~f:(Printf.sprintf "'%s'")
    |> String.concat ~sep:", "
  in
  let user_error_message =
    Printf.sprintf
      "Expected form fields %s, but got: %s"
      expected
      (concat_form_fields form_fields)
  in
  Dream.html ~status:`Bad_Request user_error_message

(** Inform the user of an invalid form *)
let invalid_form_error request =
  Dream.error (fun log ->
    log ~request "invalid form");
  Dream.html ~status:`Bad_Request "Invalid form"

let handle_rsvp config request =
  Dream.info (fun log -> log ~request "handling RSVP");

  (* parse the body of the request as a form *)
  let%lwt body = Dream.form request in

  match body with
  | `Ok ["guest_count", guest_count; "name", name] -> (

    (* validate the RSVP info *)
    let validation_result = Rsvp.(
      Validate.name name
      >>= fun name -> Validate.guest_count guest_count
      >>= fun guest_count -> Ok (name, guest_count)
    ) in

    match validation_result with 
    | Ok (valid_name, valid_guest_count) ->
      (* add the RSVP to the CSV *)
      Dream.info (fun log -> log ~request "adding RSVP for '%s' with %s guests" name guest_count);
      let%lwt () = Rsvp.add ~data_dir:config.data_dir ~name:valid_name ~guest_count:valid_guest_count in
      Dream.redirect request "/rsvp/thank-you"
    | Error error ->
      (* Return a validation error *)
      Dream.error (fun log ->
        log ~request "invalid RSVP: %s" error);
      Dream.html ~status:`Bad_Request (Printf.sprintf "Invalid RSVP: %s" error)
  ) 

  | `Ok form_fields ->
    invalid_form_fields
      request
      ~form_fields
      ~expected:["guest_count"; "name"]
  | _ ->
    invalid_form_error request

let handle_note config request =
  Dream.info (fun log -> log "handling note");

  (* parse the body of the request as a multipart form *)
  let%lwt body = Dream.multipart request in
  match body with
  | `Ok [
    "name", [None, name];
    "note", [None, note];
    "user_image", [Some file_name, user_image];
  ] -> (
      let data_dir = config.data_dir in
      let extension = File.Name.extract_extension file_name in

      let validation_result = Note.(
        Validate.name name
        >>= fun name -> Validate.note note
        >>= fun note -> Validate.image user_image
        >>= fun user_image -> Ok (name, note, user_image)
      ) in

      match validation_result with
      | Ok (name, note, user_image) ->
        let%lwt () = Note.save_user_note
          ~data_dir
          ~name
          ~note
          ~image:user_image
          ~extension
        in
        Dream.redirect request "/note/thank-you"
      | Error error ->
        Dream.error (fun log ->
          log "invalid note: %s" error);
          Dream.html ~status:`Bad_Request (Printf.sprintf "Invalid note: %s" error)
  )
  | `Ok form_fields ->
    invalid_form_fields
      request
      ~form_fields
      ~expected:["csrf"; "name"; "note"; "user_image"]
  | `Expired (_, _) ->
    Dream.error (fun log ->
      log "CSRF token expired");
    Dream.html ~status:`Bad_Request "CSRF token expired"
  | `Wrong_session _ ->
    Dream.error (fun log ->
      log "CSRF token mismatch");
    Dream.html ~status:`Bad_Request "CSRF token mismatch"
  | _ ->
    invalid_form_error request

let handle_csrf_token_request request =
  Dream.info (fun log -> log "handling CSRF token request");
  let csrf_token = Dream.csrf_token request in
  Dream.respond csrf_token