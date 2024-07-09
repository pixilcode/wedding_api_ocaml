open Core
open Core.Result.Monad_infix

type config =
  { data_dir : string
  }

let handle_rsvp config request =
  Dream.info (fun log -> log ~request "handling RSVP");

  (* parse the body of the request as a form *)
  let%lwt body = Dream.form ~csrf:false request in

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
    (* Inform the user of invalid form fields *)
    let form_field_keys = 
      form_fields
      |> List.map ~f:fst
      |> List.map ~f:(Printf.sprintf "'%s'")
      |> String.concat ~sep:", "
    in
    Dream.error (fun log ->
      log ~request "incorrect form fields: %s" form_field_keys);
    let user_error_message =
      Printf.sprintf
        "Expected form fields 'name' and 'guest_count', but got: %s"
        form_field_keys
    in
    Dream.html ~status:`Bad_Request user_error_message
  | _ ->
    Dream.error (fun log ->
      log ~request "invalid form");
    Dream.html ~status:`Bad_Request "Invalid form"

let handle_note _config _request = failwith "unimplemented"