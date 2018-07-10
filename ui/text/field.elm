module Text.Field exposing (..)

import Field

import Ports exposing (ckEditor, ckEditorSetHtml, CKEditorID, CKEditorText, addClassToCKEditor, selectAllInputText)

type alias TextFieldAttributes = (Field.FieldAttributes { name: String })

type TextTitle = TextTitle TextFieldAttributes
type TextIntro = TextIntro TextFieldAttributes
type TextTags = TextTags TextFieldAttributes

type TextFields = TextFields TextTitle TextIntro TextTags


intro : TextFields -> TextIntro
intro (TextFields _ text_intro _) =
  text_intro

title : TextFields -> TextTitle
title (TextFields text_title _ _) =
  text_title

tags : TextFields -> TextTags
tags (TextFields _ _ text_tags) =
  text_tags

set_intro : TextFields -> TextFieldAttributes -> TextFields
set_intro (TextFields text_title _ text_tags) field_attrs =
  TextFields text_title (TextIntro field_attrs) text_tags

set_title : TextFields -> TextFieldAttributes -> TextFields
set_title (TextFields _ text_intro text_tags) field_attrs =
  TextFields (TextTitle field_attrs) text_intro text_tags

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

post_toggle_intro : TextIntro -> Cmd msg
post_toggle_intro (TextIntro attrs) =
  Cmd.batch [ckEditor attrs.id, addClassToCKEditor (attrs.id, "text_introduction")]

post_toggle_title : TextTitle -> Cmd msg
post_toggle_title (TextTitle attrs) =
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
