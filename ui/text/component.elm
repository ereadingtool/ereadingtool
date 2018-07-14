module Text.Component exposing (TextComponent, emptyTextComponent, text_section_components, set_text_section_components
  , text, set_text_attribute, init, update_text_errors, reinitialize_ck_editors, set_title_editable, post_toggle_title
  , post_toggle_author, post_toggle_intro, post_toggle_source, set_intro_editable, text_fields, add_tag, remove_tag
  , tags, set_author_editable, set_source_editable)

import Text.Model as Text exposing (Text)
import Text.Field exposing (TextFields, init_text_fields, TextIntro, TextTitle, TextTags)

import Text.Section.Component.Group exposing (TextSectionComponentGroup)

import Array
import Dict exposing (Dict)
import Ports exposing (ckEditor, ckEditorSetHtml, CKEditorID, CKEditorText, addClassToCKEditor, selectAllInputText)

type alias TextAttributeName = String

type alias TextTags = Dict String String

type TextComponent = TextComponent Text TextFields TextTags TextSectionComponentGroup

init : Text -> TextComponent
init text =
  TextComponent text init_text_fields (tags_to_dict text.tags) (Text.Section.Component.Group.fromTextSections text.sections)

text : TextComponent -> Text
text (TextComponent text _ text_tags component_group) =
  Text.set_tags
    (Text.set_sections text (Text.Section.Component.Group.toTextSections component_group))
    (Just <| Dict.keys text_tags)

text_fields : TextComponent -> TextFields
text_fields (TextComponent _ text_fields _ _) =
  text_fields

set_text_fields : TextComponent -> TextFields -> TextComponent
set_text_fields text_component text_fields =
  text_component

set_intro_editable : TextComponent -> Bool -> TextComponent
set_intro_editable (TextComponent text text_fields text_tags component_group) editable =
  let
    (Text.Field.TextIntro intro_field_attrs) = Text.Field.intro text_fields
    new_text_fields = Text.Field.set_intro text_fields { intro_field_attrs | editable = editable }
  in
    TextComponent text new_text_fields text_tags component_group

set_title_editable : TextComponent -> Bool -> TextComponent
set_title_editable (TextComponent text text_fields text_tags component_group) editable =
  let
    (Text.Field.TextTitle title_field_attrs) = Text.Field.title text_fields
    new_text_fields = Text.Field.set_title text_fields { title_field_attrs | editable = editable }
  in
    TextComponent text new_text_fields text_tags component_group

set_author_editable : TextComponent -> Bool -> TextComponent
set_author_editable (TextComponent text text_fields text_tags component_group) editable =
  let
    (Text.Field.TextAuthor text_author_attrs) = Text.Field.author text_fields
    new_text_fields = Text.Field.set_author text_fields { text_author_attrs | editable = editable }
  in
    TextComponent text new_text_fields text_tags component_group

set_source_editable : TextComponent -> Bool -> TextComponent
set_source_editable (TextComponent text text_fields text_tags component_group) editable =
  let
    (Text.Field.TextSource text_source_attrs) = Text.Field.source text_fields
    new_text_fields = Text.Field.set_source text_fields { text_source_attrs | editable = editable }
  in
    TextComponent text new_text_fields text_tags component_group

text_section_components : TextComponent -> TextSectionComponentGroup
text_section_components (TextComponent _ _ _ components) =
  components

set_text_section_components : TextComponent -> TextSectionComponentGroup -> TextComponent
set_text_section_components (TextComponent text fields text_tags _) new_components =
  TextComponent text fields text_tags new_components

-- TODO(andrew): use field types instead of strings
set_text_attribute : TextComponent -> TextAttributeName -> String -> TextComponent
set_text_attribute ((TextComponent text fields text_tags components) as text_component) attr_name value =
  case attr_name of
    "title" -> TextComponent { text | title = value } fields text_tags components
    "introduction" -> TextComponent { text | introduction = value } fields text_tags components
    "author" -> TextComponent { text | author = value } fields text_tags components
    "source" -> TextComponent { text | source = value } fields text_tags components
    "difficulty" -> TextComponent { text | difficulty = value } fields text_tags components
    _ -> text_component

emptyTextComponent : TextComponent
emptyTextComponent =
  TextComponent Text.new_text init_text_fields (Dict.fromList []) (Text.Section.Component.Group.new_group)

reinitialize_ck_editors : TextComponent -> Cmd msg
reinitialize_ck_editors ((TextComponent text fields text_tags components) as text_component) =
  let
    text_component_group = text_section_components text_component
    intro_field_id = Text.Field.intro_id (Text.Field.intro fields)
  in
    Cmd.batch [
      Cmd.batch [ckEditor intro_field_id, ckEditorSetHtml (intro_field_id, text.introduction)]
    , Text.Section.Component.Group.reinitialize_ck_editors text_component_group ]

update_text_errors : TextComponent -> Dict String String -> TextComponent
update_text_errors (TextComponent text fields text_tags components) errors =
  let
    _ = (Debug.log "text errors" errors)
    new_text_component =
      TextComponent
        text (Array.foldr Text.Field.update_error fields (Array.fromList <| Dict.toList errors)) text_tags components
    text_sections =
      Text.Section.Component.Group.update_errors (text_section_components new_text_component) errors
  in
    (set_text_section_components new_text_component text_sections)

tags_to_dict : Maybe (List String) -> Dict String String
tags_to_dict tags =
  case tags of
    Just tags_list ->
      Dict.fromList <| List.map (\tag -> (tag, tag)) tags_list
    _ -> Dict.fromList []

tags : TextComponent -> Dict String String
tags (TextComponent _ _ text_tags _) =
  text_tags

add_tag : TextComponent -> String -> TextComponent
add_tag ((TextComponent text fields text_tags components) as text_component) tag =
  TextComponent text fields (Dict.insert tag tag text_tags) components

remove_tag : TextComponent -> String -> TextComponent
remove_tag ((TextComponent text fields text_tags components) as text_component) tag =
  TextComponent text fields (Dict.remove tag text_tags) components

post_toggle_title : TextComponent -> Cmd msg
post_toggle_title ((TextComponent text fields text_tags components) as text_component) =
  Text.Field.post_toggle_title (Text.Field.title fields)

post_toggle_intro : TextComponent -> Cmd msg
post_toggle_intro ((TextComponent text fields text_tags components) as text_component) =
  Text.Field.post_toggle_intro (Text.Field.intro fields)

post_toggle_author : TextComponent -> Cmd msg
post_toggle_author ((TextComponent text fields text_tags components) as text_component) =
  Text.Field.post_toggle_author (Text.Field.author fields)

post_toggle_source : TextComponent -> Cmd msg
post_toggle_source ((TextComponent text fields text_tags components) as text_component) =
  Text.Field.post_toggle_source (Text.Field.source fields)
