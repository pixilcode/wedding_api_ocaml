(** Add the given name and count to the RSVP CSV file *)
val add : path:string -> name:string -> guest_count:int -> unit Lwt.t
