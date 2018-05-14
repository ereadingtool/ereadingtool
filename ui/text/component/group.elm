module Text.Component.Group exposing (TextComponentGroup, update_text_components, add_new_text, update_errors
  , new_group, toArray)

import Array exposing (Array)
import Dict exposing (Dict)

import Text.Component exposing (TextComponent)

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