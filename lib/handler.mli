(** Configuration for the handlers *)
type config =
  { data_dir : string
  }

(**
	Handle an RSVP

	Expects the request body to be a form with [name] and [guest_count].
*)
val handle_rsvp : config -> Dream.handler

(**
	Handle a note

	Expects the request body to be a form with [name], [note], and an optional
	[image] of the sender.
*)
val handle_note : config -> Dream.handler

(**
	Handle a request for a CSRF token
*)
val handle_csrf_token_request : Dream.handler
