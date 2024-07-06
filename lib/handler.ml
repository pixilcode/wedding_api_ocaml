open Core

type config =
  { data_dir : string
  }

let handle_rsvp config request =
  Dream.info (fun log -> log ~request "handling RSVP");

  (* parse the body of the request as a form *)
  let%lwt body = Dream.form ~csrf:false request in

  match body with
  | `Ok ["guest_count", guest_count; "name", name] -> (
    (* check if the `guest_count` field is an integer *)
    match Int.of_string_opt guest_count with 
      | Some guest_count when guest_count >= 0 ->
        Dream.info (fun log -> log ~request "adding RSVP for '%s' with %d guests" name guest_count);

        (* add the RSVP to the CSV *)
        let%lwt () = Rsvp.add ~path:(config.data_dir ^ "/rsvp.csv") ~name ~guest_count in
        Dream.redirect request "/rsvp/thank-you" (* TODO: don't redirect once form on webpage doesn't require redirect *)
      | _ ->
        Dream.error (fun log ->
          log ~request "invalid guest count '%s'" guest_count);
        Dream.empty `Bad_Request
  )
  | `Ok form_fields ->
    let form_field_keys = 
      form_fields
      |> List.map ~f:fst
      |> List.map ~f:(Printf.sprintf "'%s'")
      |> String.concat ~sep:", "
    in
    Dream.error (fun log ->
      log ~request "incorrect form fields: %s" form_field_keys);
    Dream.empty `Bad_Request
  | _ ->
    Dream.error (fun log ->
      log ~request "invalid form");
    Dream.empty `Bad_Request

let handle_note _config _request = failwith "unimplemented"