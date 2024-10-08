open Wedding_api
open Core

let test_path = "test.txt"

let concat_fields form_fields: string =
  form_fields
  |> List.map ~f:(fun (key, value) -> Printf.sprintf "%s=%s\n" key value)
  |> String.concat

let decode_basic_auth auth_header =
  match String.split ~on:' ' auth_header with
  | "Basic" :: encoded :: _ -> (
    Some (Base64.decode_exn encoded)
  )
  | _ -> None


let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/file" (fun _ ->
      let%lwt contents = File.read_file test_path in
      Dream.html contents
    );
    
    Dream.post "/createFile" (fun _ ->
      let%lwt () = File.create_file test_path in
      Dream.html "file created!\n"
    );

    Dream.put "/updateContents" (fun request ->
      let%lwt body = Dream.form ~csrf:false request in
      match body with
      | `Ok form_fields ->
        let file_contents = concat_fields form_fields in
        let%lwt () = File.write_to_file test_path file_contents in
        Dream.html "Updated!\n"
      | _ -> Dream.empty `Bad_Request
    );

    Dream.get "/authenticated" (fun request ->
      let auth_header = Dream.header request "Authorization" in
      match auth_header with
      | Some auth_header ->
        let decoded = decode_basic_auth auth_header in
        let body = match decoded with
          | Some decoded -> Printf.sprintf "Header: '%s'\nDecoded value: '%s'" auth_header decoded
          | None -> "Invalid Authorization header"
        in
        Dream.html body
      | None -> (
        Dream.respond
          ~status:`Unauthorized
          ~headers:["WWW-Authenticate", "Basic realm=\"Dream\""]
          "Unauthorized"
      )
    );

    Dream.post "/submitForm" (fun request ->
      let%lwt body = Dream.multipart ~csrf:false request in
      match body with
      | `Ok [
        "image", [ Some file_name, file ];
        "image-name", [ None, image_name ]
      ] ->
        let%lwt () = File.write_to_file ~append:false file_name file in
        let body = Printf.sprintf "File name: <code>%s</code><br>Image name: <code>%s</code>" file_name image_name in
        Dream.html body
      | _ -> Dream.empty `Bad_Request
    );
   ]