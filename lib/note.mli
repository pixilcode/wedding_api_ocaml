(** Validation functions *)
module Validate : sig
  type validated_name
  type validated_note
  type validated_image
  val name : string -> (validated_name, string) result
  val note : string -> (validated_note, string) result
  val image : string -> (validated_image, string) result
end

(** Save the user's note to the given [data_dir] *)
val save_user_note :
	data_dir: string
	-> name: Validate.validated_name
	-> note: Validate.validated_note
	-> image: Validate.validated_image
	-> extension: string option
	-> unit Lwt.t