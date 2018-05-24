module Text.Component.Group exposing (TextComponentGroup, update_text_components, add_new_text, update_errors
  , new_group, toArray, update_body_for_id, toTexts, fromTexts, reinitialize_ck_editors)

import Array exposing (Array)
import Dict exposing (Dict)

import Text.Model
import Text.Component exposing (TextComponent)
import Ports exposing (ckEditor, CKEditorID, CKEditorText)

type TextComponentGroup = TextComponentGroup (Array TextComponent)


new_group : TextComponentGroup
new_group = (TextComponentGroup (Array.fromList [Text.Component.emptyTextComponent 0]))

-- TODO: maps an error dictionary to a list of text components
update_errors : TextComponentGroup -> (Dict String String) -> TextComponentGroup
update_errors (TextComponentGroup text_components) errors =
   TextComponentGroup text_components

update_text_components : TextComponentGroup -> TextComponent -> TextComponentGroup
update_text_components (TextComponentGroup text_components) text_component =
  TextComponentGroup (Array.set (Text.Component.index text_component) text_component text_components)

add_new_text : TextComponentGroup -> TextComponentGroup
add_new_text (TextComponentGroup text_components) = let
    arr_len = Array.length text_components
  in
    TextComponentGroup (Array.push (Text.Component.emptyTextComponent arr_len) text_components)

toArray : TextComponentGroup -> Array TextComponent
toArray (TextComponentGroup text_components) = text_components

toTexts : TextComponentGroup -> Array Text.Model.Text
toTexts text_components = Array.map Text.Component.toText (toArray text_components)

fromTexts : Array Text.Model.Text -> TextComponentGroup
fromTexts texts =
  TextComponentGroup (Array.indexedMap Text.Component.fromText texts)

text_component : TextComponentGroup -> Int -> Maybe TextComponent
text_component (TextComponentGroup text_components) index = Array.get index text_components

reinitialize_ck_editors : TextComponentGroup -> Cmd msg
reinitialize_ck_editors text_component_group =
  let
    text_components = toArray text_component_group
  in
    Cmd.batch <| Array.toList <| Array.map Text.Component.reinitialize_ck_editor text_components

update_body_for_id : TextComponentGroup -> CKEditorID -> CKEditorText -> TextComponentGroup
update_body_for_id text_components ckeditor_id ckeditor_text =
  case String.split "_" ckeditor_id of
    ["text", i, "body"] ->
      case String.toInt i of
        Ok i ->
          case text_component text_components i of
             Just text_component ->
               update_text_components text_components (Text.Component.update_body text_component ckeditor_text)
             _ -> text_components
        _ -> text_components
    _ -> text_components
