open Wedding_api
open Core

let () =
  print_endline "starting server...";
  let config: Handler.config = { data_dir = "_test/" } in
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.scope "/api" [] [
      Dream.post "/rsvp" (Handler.handle_rsvp config);
      Dream.post "/note" (Handler.handle_note config);
    ];
  ]