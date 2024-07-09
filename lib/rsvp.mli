(** Validation functions *)
module Validate : sig
  type validated_name
  type validated_guest_count
  val name : string -> (validated_name, string) result
  val guest_count : string -> (validated_guest_count, string) result
end

(** Add the given name and count to the RSVP CSV file *)
val add : data_dir : string -> name : Validate.validated_name -> guest_count : Validate.validated_guest_count -> unit Lwt.t
