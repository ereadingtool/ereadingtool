module Text.Field exposing (..)

import Field

import Ports exposing (ckEditor, ckEditorSetHtml, CKEditorID, CKEditorText, addClassToCKEditor, selectAllInputText)

type alias TextFieldAttributes = (Field.FieldAttributes { name: String })

type TextTitle = TextTitle TextFieldAttributes
type TextIntro = TextIntro TextFieldAttributes
type TextTags = TextTags TextFieldAttributes
type TextAuthor = TextAuthor TextFieldAttributes
type TextSource = TextSource TextFieldAttributes
type TextDifficulty = TextDifficulty TextFieldAttributes
type TextConclusion = TextConclusion TextFieldAttributes

type TextFields = TextFields TextTitle TextIntro TextTags TextAuthor TextSource TextDifficulty TextConclusion


update_error : (String, String) -> TextFields -> TextFields
update_error (field_id, field_error)
  ((TextFields
    (TextTitle title_attrs)
    (TextIntro intro_attrs)
    (TextTags tags_attrs)
    (TextAuthor author_attrs)
    (TextSource source_attrs)
    (TextDifficulty difficulty_attrs)
    (TextConclusion conclusion_attrs)) as text_fields) =
  let
    -- error keys begin with text_*
    error_key = String.split "_" field_id
  in
    case error_key of
      "text" :: field_name :: [] ->
        case field_name of
          "introduction" ->
            set_intro text_fields { intro_attrs | error_string = field_error, error = True }

          "conclusion" ->
            set_conclusion text_fields { conclusion_attrs | error_string = field_error, error = True }

          "title" ->
            set_title text_fields { title_attrs | error_string = field_error, error = True }

          "author" ->
            set_author text_fields { author_attrs | error_string = field_error, error = True }

          "source" ->
            set_source text_fields { source_attrs | error_string = field_error, error = True }

          "tags" ->
            set_tags text_fields { tags_attrs | error_string = field_error, error = True }

          _ -> text_fields -- not a valid field name

      _ -> text_fields -- no text errors

title : TextFields -> TextTitle
title (TextFields text_title _ _ _ _ _ _) =
  text_title

text_title_attrs : TextTitle -> TextFieldAttributes
text_title_attrs (TextTitle attrs) = attrs

intro : TextFields -> TextIntro
intro (TextFields _ text_intro _ _ _ _ _) =
  text_intro

text_intro_attrs : TextIntro -> TextFieldAttributes
text_intro_attrs (TextIntro attrs) = attrs

tags : TextFields -> TextTags
tags (TextFields _ _ text_tags _ _ _ _) =
  text_tags

text_tags_attrs : TextTags -> TextFieldAttributes
text_tags_attrs (TextTags attrs) = attrs

author : TextFields -> TextAuthor
author (TextFields _ _ _ text_author _ _ _) =
  text_author

text_author_attrs : TextAuthor -> TextFieldAttributes
text_author_attrs (TextAuthor attrs) = attrs

source : TextFields -> TextSource
source (TextFields _ _ _ _ text_source _ _) =
  text_source

text_source_attrs : TextSource -> TextFieldAttributes
text_source_attrs (TextSource attrs) = attrs

difficulty : TextFields -> TextDifficulty
difficulty (TextFields _ _ _ _ _ text_difficulty _) =
  text_difficulty

conclusion : TextFields -> TextConclusion
conclusion (TextFields _ _ _ _ _ _ text_conclusion) =
  text_conclusion

text_conclusion_attrs : TextConclusion -> TextFieldAttributes
text_conclusion_attrs (TextConclusion attrs) = attrs

set_title : TextFields -> TextFieldAttributes -> TextFields
set_title (TextFields _ text_intro text_tags text_author text_source text_difficulty text_conclusion) field_attrs =
  TextFields (TextTitle field_attrs) text_intro text_tags text_author text_source text_difficulty text_conclusion

set_intro : TextFields -> TextFieldAttributes -> TextFields
set_intro (TextFields text_title _ text_tags text_author text_source text_difficulty text_conclusion) field_attrs =
  TextFields text_title (TextIntro field_attrs) text_tags text_author text_source text_difficulty text_conclusion

set_tags : TextFields -> TextFieldAttributes -> TextFields
set_tags
  (TextFields text_title text_intro text_tags text_author text_source text_difficulty text_conclusion) field_attrs =
    TextFields text_title text_intro (TextTags field_attrs) text_author text_source text_difficulty text_conclusion

set_author : TextFields -> TextFieldAttributes -> TextFields
set_author
  (TextFields text_title text_intro text_tags text_author text_source text_difficulty text_conclusion) field_attrs =
    TextFields text_title text_intro text_tags (TextAuthor field_attrs) text_source text_difficulty text_conclusion

set_source : TextFields -> TextFieldAttributes -> TextFields
set_source
  (TextFields text_title text_intro text_tags text_author text_source text_difficulty text_conclusion) field_attrs =
    TextFields text_title text_intro text_tags text_author (TextSource field_attrs) text_difficulty text_conclusion

set_difficulty : TextFields -> TextFieldAttributes -> TextFields
set_difficulty
  (TextFields text_title text_intro text_tags text_author text_source text_difficulty text_conclusion) field_attrs =
    TextFields text_title text_intro text_tags text_author text_source (TextDifficulty field_attrs) text_conclusion

set_conclusion : TextFields -> TextFieldAttributes -> TextFields
set_conclusion (TextFields text_title text_intro text_tags text_author text_source text_difficulty _) field_attrs =
  TextFields text_title text_intro text_tags text_author text_source text_difficulty (TextConclusion field_attrs)

post_toggle_intro : TextIntro -> Cmd msg
post_toggle_intro (TextIntro attrs) =
  Cmd.batch [ckEditor attrs.input_id, addClassToCKEditor (attrs.input_id, "text_introduction")]

post_toggle_conclusion : TextConclusion -> Cmd msg
post_toggle_conclusion (TextConclusion attrs) =
  Cmd.batch [ckEditor attrs.input_id, addClassToCKEditor (attrs.input_id, "text_conclusion")]

post_toggle_title : TextTitle -> Cmd msg
post_toggle_title (TextTitle attrs) =
  selectAllInputText attrs.input_id

post_toggle_author : TextAuthor -> Cmd msg
post_toggle_author (TextAuthor attrs) =
  if attrs.editable then
    selectAllInputText attrs.input_id
  else
    Cmd.none

post_toggle_source : TextSource -> Cmd msg
post_toggle_source (TextSource attrs) =
  selectAllInputText attrs.input_id

init_text_fields : TextFields
init_text_fields =
  TextFields
  (TextTitle ({
        id="text_title"
      , input_id="text_title_input"
      , editable=False
      , error_string=""
      , error=False
      , name="title"
      , index=0 }))
  (TextIntro ({
        id="text_introduction"
      , input_id="text_introduction_input"
      , editable=False
      , error_string=""
      , error=False
      , name="introduction"
      , index=2 }))
  (TextTags ({
        id="text_tags"
      , input_id="text_tags_input"
      , editable=False
      , error_string=""
      , error=False
      , name="tags"
      , index=1 }))
  (TextAuthor ({
        id="text_author"
      , input_id="text_author_input"
      , editable=False
      , error_string=""
      , error=False
      , name="author"
      , index=3 }))
  (TextSource ({
        id="text_source"
      , input_id="text_source_input"
      , editable=False
      , error_string=""
      , error=False
      , name="source"
      , index=4 }))
  (TextDifficulty ({
        id="text_difficulty"
      , input_id="text_difficulty_input"
      , editable=False
      , error_string=""
      , error=False
      , name="difficulty"
      , index=5 }))
  (TextConclusion ({
        id="text_conclusion"
      , input_id="text_conclusion_input"
      , editable=False
      , error_string=""
      , error=False
      , name="conclusion"
      , index=6 }))
