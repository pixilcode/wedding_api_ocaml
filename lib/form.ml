let html_to_string html =
  let open Tyxml in
  Format.asprintf "%a" (Html.pp_elt ()) html

let csrf_tag request =
  let tag_value = Dream.csrf_token request in

  Tyxml.Html.(
    input ~a:[a_name "dream.csrf"; a_input_type `Hidden; a_value tag_value] ()
  )

let note_form request =
  let open Tyxml.Html in
  let form = form ~a:[a_method `Post; a_action "/api/note"; a_enctype "multipart/form-data"] [
    csrf_tag request;
    div ~a:[a_class ["field name"]] [
      label ~a:[a_label_for "name"] [txt "Name"];
      input ~a:[
        a_name "name";
        a_id "name";
        a_required ();
        a_placeholder "Your name";
        a_input_type `Text
      ] ();
    ];
    div ~a:[a_class ["field note"]] [
      label ~a:[a_label_for "note"] [txt "Note"];
      textarea ~a:[
        a_name "note";
        a_id "note";
        a_required ();
      ] (txt "");
    ];
    div ~a:[a_class ["field user-image"]] [
      label ~a:[a_label_for "user-image"] [txt "Image"];
      input ~a:[
        a_name "user_image";
        a_id "user-image";
        a_input_type `File;
      ] ();
    ];
    button [txt "Send"];
  ] in
  html_to_string form