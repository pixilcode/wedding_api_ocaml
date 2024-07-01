open Core


let create_file ?(contents="hello world!\n") path =
  Out_channel.with_file path ~f:(fun file ->
    Out_channel.output_string file contents
  )

let read_file path =
  In_channel.with_file path ~f:(fun file ->
    let contents = In_channel.input_all file in
    contents
  )

let write_to_file ?(append=true) path contents =
  Out_channel.with_file ~append path ~f:(fun file ->
    Out_channel.output_string file contents
  )
