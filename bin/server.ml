open Wedding_api
open Core

(* TODO: accept port and data dir as arguments as well *)
(* TODO: create config file option for redirect actions for `/rsvp` and `/note` *)

let random_secret () =
  Dream.random 32
  |> Dream.to_base64url

let () =
  Dream.log "Starting server...";

  (* get the value of WEDDING_API_DATA_DIR, or use current dir as default *)
  let data_dir = match Sys.getenv "WEDDING_API_DATA_DIR" with
    | Some dir -> dir (* TODO: check if this is a valid dir, create it if it isn't created *)
    | None -> "."
  in

  (* get the value of WEDDING_API_PORT, or use 5599 as default*)
  let port = Sys.getenv "WEDDING_API_PORT"
    |> Option.bind ~f:Int.of_string_opt (* TODO: if it the variable is set but an invalid int, print an error message *)
    |> Option.value ~default:5599
  in

  let dream_secret = Sys.getenv "WEDDING_API_SECRET_FILE"
    |> Option.map ~f:(fun file ->
      file
      |> In_channel.read_all
      |> String.strip
    )
    |> Option.value_or_thunk ~default:random_secret
  in

  (* create the server config *)
  let config: Handler.config = { data_dir } in

  (* start the server *)
  Dream.run ~port
  @@ Dream.set_secret dream_secret
  @@ Dream.cookie_sessions
  @@ Dream.logger
  @@ Dream.router [
    Dream.scope "/api" [] [
      Dream.any "/health" (fun _ -> Dream.html "Healthy!");
      Dream.post "/rsvp" (Handler.handle_rsvp config);
      Dream.post "/note" (Handler.handle_note config);
      Dream.get "/note/form" Handler.handle_note_form_request;
    ];
  ]