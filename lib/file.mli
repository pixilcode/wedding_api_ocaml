(** Prepend the current datetime to the given file name *)
val prepend_datetime_to : string -> string

(** Extract the extension from the file name *)
val extract_extension : string -> string option

(** Convert the string into a valid file name string *)
val filename_string_of : string -> string

(**
	Create a file with optional [contents] at the given path

	This function will overwrite the file if it already exists
*)
val create_file : ?contents:string -> string -> unit Lwt.t

(**
	Create a directory at the given path if it doesn't already exist
	
	[permissions] defaults to 0o755 (rwxr-xr-x)
*)
val create_dir : ?permissions:int -> string -> unit Lwt.t

(** Read from the file at the given path *)
val read_file : string -> string Lwt.t

(**
	Write to the file at the given path
	
	This function fails if the file doesn't already exist
*)
val write_to_file : ?append:bool -> string -> string -> unit Lwt.t
