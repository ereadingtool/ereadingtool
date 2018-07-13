module Text.Section.Component.Group exposing (TextSectionComponentGroup, update_components, add_new_text
  , update_errors,new_group, toArray, update_body_for_id, toTextSections, fromTextSections, reinitialize_ck_editors, delete_text_section
  , text_component)

import Array exposing (Array)
import Dict exposing (Dict)

import Text.Section.Model

import Text.Section.Component exposing (TextSectionComponent)
import Ports exposing (ckEditor, CKEditorID, CKEditorText)

type TextSectionComponentGroup = TextSectionComponentGroup (Array TextSectionComponent)


new_group : TextSectionComponentGroup
new_group = (TextSectionComponentGroup (Array.fromList [Text.Section.Component.emptyTextSectionComponent 0]))

update_error : (String, String) -> Array TextSectionComponent -> Array TextSectionComponent
update_error (field_id, field_error) text_components =
  -- error keys begin with text_i_*
  let
    error_key = String.split "_" field_id
  in
    case error_key of
      "text" :: index :: _ ->
        case String.toInt index of
          Ok i ->
            case Array.get i text_components of
              Just text_component ->
                let
                  -- only pass the relevant part of the error key
                  text_component_error = String.join "_" (List.drop 2 error_key)
                  new_text_component_with_errors =
                    (Text.Section.Component.update_errors text_component (text_component_error, field_error))
                in
                  Array.set i new_text_component_with_errors text_components
              Nothing -> text_components -- text doesn't exist in the group
          _ -> text_components -- not a valid index string
      _ -> text_components -- not a valid error key

update_errors : TextSectionComponentGroup -> (Dict String String) -> TextSectionComponentGroup
update_errors ((TextSectionComponentGroup text_components) as text_component_group) errors =
   TextSectionComponentGroup (Array.foldr update_error (toArray text_component_group) (Array.fromList <| Dict.toList errors))

update_components : TextSectionComponentGroup -> TextSectionComponent -> TextSectionComponentGroup
update_components (TextSectionComponentGroup text_components) text_component =
  TextSectionComponentGroup (Array.set (Text.Section.Component.index text_component) text_component text_components)

add_new_text : TextSectionComponentGroup -> TextSectionComponentGroup
add_new_text (TextSectionComponentGroup text_components) =
  let
    arr_len = Array.length text_components
  in
    TextSectionComponentGroup (Array.push (Text.Section.Component.emptyTextSectionComponent arr_len) text_components)

delete_text_section : TextSectionComponentGroup -> TextSectionComponent -> TextSectionComponentGroup
delete_text_section (TextSectionComponentGroup text_components) text_section_component =
  let
    index = Text.Section.Component.index
    arr_len = Array.length text_components
    component_index = index text_section_component
    new_text_components =
        Array.indexedMap (\i text_component -> Text.Section.Component.set_index text_component i)
     <| Array.filter (\text_component -> index text_component /= component_index) text_components
  in
    TextSectionComponentGroup new_text_components

toArray : TextSectionComponentGroup -> Array TextSectionComponent
toArray (TextSectionComponentGroup text_components) = text_components

toTextSections : TextSectionComponentGroup -> Array Text.Section.Model.TextSection
toTextSections text_components = Array.map Text.Section.Component.toTextSection (toArray text_components)

fromTextSections : Array Text.Section.Model.TextSection -> TextSectionComponentGroup
fromTextSections text_sections =
  TextSectionComponentGroup (Array.indexedMap Text.Section.Component.fromTextSection text_sections)

text_component : TextSectionComponentGroup -> Int -> Maybe TextSectionComponent
text_component (TextSectionComponentGroup text_components) index = Array.get index text_components

reinitialize_ck_editors : TextSectionComponentGroup -> Cmd msg
reinitialize_ck_editors text_component_group =
  let
    text_components = toArray text_component_group
  in
    Cmd.batch <| Array.toList <| Array.map Text.Section.Component.reinitialize_ck_editor text_components

update_body_for_id : TextSectionComponentGroup -> CKEditorID -> CKEditorText -> TextSectionComponentGroup
update_body_for_id text_components ckeditor_id ckeditor_text =
  case String.split "_" ckeditor_id of
    ["text", i, "body"] ->
      case String.toInt i of
        Ok i ->
          case text_component text_components i of
             Just text_component ->
               update_components text_components (Text.Section.Component.update_body text_component ckeditor_text)
             _ -> text_components
        _ -> text_components
    _ -> text_components
