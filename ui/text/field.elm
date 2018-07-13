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

type TextFields = TextFields TextTitle TextIntro TextTags TextAuthor TextSource TextDifficulty


title : TextFields -> TextTitle
title (TextFields text_title _ _ _ _ _) =
  text_title

intro : TextFields -> TextIntro
intro (TextFields _ text_intro _ _ _ _) =
  text_intro

tags : TextFields -> TextTags
tags (TextFields _ _ text_tags _ _ _) =
  text_tags

author : TextFields -> TextAuthor
author (TextFields _ _ _ text_author _ _) =
  text_author

source : TextFields -> TextSource
source (TextFields _ _ _ _ text_source _) =
  text_source

difficulty : TextFields -> TextDifficulty
difficulty (TextFields _ _ _ _ _ text_difficulty) =
  text_difficulty

set_intro : TextFields -> TextFieldAttributes -> TextFields
set_intro (TextFields text_title _ text_tags text_author text_source text_difficulty) field_attrs =
  TextFields text_title (TextIntro field_attrs) text_tags text_author text_source text_difficulty

set_title : TextFields -> TextFieldAttributes -> TextFields
set_title (TextFields _ text_intro text_tags text_author text_source text_difficulty) field_attrs =
  TextFields (TextTitle field_attrs) text_intro text_tags text_author text_source text_difficulty

set_author : TextFields -> TextFieldAttributes -> TextFields
set_author (TextFields text_title text_intro text_tags text_author text_source text_difficulty) field_attrs =
  TextFields text_title text_intro text_tags (TextAuthor field_attrs) text_source text_difficulty

set_source : TextFields -> TextFieldAttributes -> TextFields
set_source (TextFields text_title text_intro text_tags text_author text_source text_difficulty) field_attrs =
  TextFields text_title text_intro text_tags text_author (TextSource field_attrs) text_difficulty

intro_error : TextIntro -> Bool
intro_error (TextIntro attrs) = attrs.error

intro_editable : TextIntro -> Bool
intro_editable (TextIntro attrs) = attrs.editable

intro_id : TextIntro -> String
intro_id (TextIntro attrs) = attrs.id

title_editable : TextTitle -> Bool
title_editable (TextTitle attrs) = attrs.editable

title_id : TextTitle -> String
title_id (TextTitle attrs) = attrs.id

title_error : TextTitle -> Bool
title_error (TextTitle attrs) = attrs.error

tag_error : TextTags -> Bool
tag_error (TextTags attrs) = attrs.error

author_id : TextAuthor -> String
author_id (TextAuthor attrs) = attrs.id

author_error : TextAuthor -> Bool
author_error (TextAuthor attrs) = attrs.error

author_editable : TextAuthor -> Bool
author_editable (TextAuthor attrs) = attrs.editable

source_id : TextSource -> String
source_id (TextSource attrs) = attrs.id

source_error : TextSource -> Bool
source_error (TextSource attrs) = attrs.error

source_editable : TextSource -> Bool
source_editable (TextSource attrs) = attrs.editable

post_toggle_intro : TextIntro -> Cmd msg
post_toggle_intro (TextIntro attrs) =
  Cmd.batch [ckEditor attrs.id, addClassToCKEditor (attrs.id, "text_introduction")]

post_toggle_title : TextTitle -> Cmd msg
post_toggle_title (TextTitle attrs) =
  selectAllInputText attrs.id

post_toggle_author : TextAuthor -> Cmd msg
post_toggle_author (TextAuthor attrs) =
  if attrs.editable then
    selectAllInputText attrs.id
  else
    Cmd.none

post_toggle_source : TextSource -> Cmd msg
post_toggle_source (TextSource attrs) =
  selectAllInputText attrs.id

init_text_fields : TextFields
init_text_fields =
  TextFields
  (TextTitle ({
        id="text_title"
      , editable=False
      , error_string=""
      , error=False
      , name="title"
      , index=0 }))
  (TextIntro ({
        id="text_introduction"
      , editable=False
      , error_string=""
      , error=False
      , name="introduction"
      , index=2 }))
  (TextTags ({
        id="text_tags"
      , editable=False
      , error_string=""
      , error=False
      , name="tags"
      , index=1 }))
  (TextAuthor ({
        id="text_author"
      , editable=False
      , error_string=""
      , error=False
      , name="author"
      , index=3 }))
  (TextSource ({
        id="text_source"
      , editable=False
      , error_string=""
      , error=False
      , name="source"
      , index=4 }))
  (TextDifficulty ({
        id="text_difficulty"
      , editable=False
      , error_string=""
      , error=False
      , name="difficulty"
      , index=5 }))


