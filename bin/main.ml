open Wedding_api
open Core

let test_path = "test.txt"

let concat_fields form_fields: string =
  form_fields
  |> List.map ~f:(fun (key, value) -> Printf.sprintf "%s=%s\n" key value)
  |> String.concat

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/file" (fun _ ->
      let contents = File.read_file test_path in
      Dream.html contents);
    
    Dream.post "/createFile" (fun _ ->
      File.create_file test_path;
      Dream.html "file created!\n");

    Dream.put "/updateContents" (fun request ->
      let%lwt body = Dream.form ~csrf:false request in
      match body with
      | `Ok form_fields ->
        let file_contents = concat_fields form_fields in
        File.write_to_file test_path file_contents;
        Dream.html "Updated!\n"
      | _ -> Dream.empty `Bad_Request
    )
   ]