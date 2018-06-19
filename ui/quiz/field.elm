module Quiz.Field exposing (..)

import Field

import Ports exposing (ckEditor, ckEditorSetHtml, CKEditorID, CKEditorText, addClassToCKEditor, selectAllInputText)

type alias QuizFieldAttributes = (Field.FieldAttributes { name: String })

type QuizTitle = QuizTitle QuizFieldAttributes
type QuizIntro = QuizIntro QuizFieldAttributes
type QuizTags = QuizTags QuizFieldAttributes

type QuizFields = QuizFields QuizTitle QuizIntro QuizTags


intro : QuizFields -> QuizIntro
intro (QuizFields _ quiz_intro _) =
  quiz_intro

title : QuizFields -> QuizTitle
title (QuizFields quiz_title _ _) =
  quiz_title

tags : QuizFields -> QuizTags
tags (QuizFields _ _ quiz_tags) =
  quiz_tags

set_intro : QuizFields -> QuizFieldAttributes -> QuizFields
set_intro (QuizFields quiz_title _ quiz_tags) field_attrs =
  QuizFields quiz_title (QuizIntro field_attrs) quiz_tags

set_title : QuizFields -> QuizFieldAttributes -> QuizFields
set_title (QuizFields _ quiz_intro quiz_tags) field_attrs =
  QuizFields (QuizTitle field_attrs) quiz_intro quiz_tags

intro_error : QuizIntro -> Bool
intro_error (QuizIntro attrs) = attrs.error

intro_editable : QuizIntro -> Bool
intro_editable (QuizIntro attrs) = attrs.editable

intro_id : QuizIntro -> String
intro_id (QuizIntro attrs) = attrs.id

title_editable : QuizTitle -> Bool
title_editable (QuizTitle attrs) = attrs.editable

title_id : QuizTitle -> String
title_id (QuizTitle attrs) = attrs.id

title_error : QuizTitle -> Bool
title_error (QuizTitle attrs) = attrs.error

tag_error : QuizTags -> Bool
tag_error (QuizTags attrs) = attrs.error

post_toggle_intro : QuizIntro -> Cmd msg
post_toggle_intro (QuizIntro attrs) =
  Cmd.batch [ckEditor attrs.id, addClassToCKEditor (attrs.id, "quiz_introduction")]

post_toggle_title : QuizTitle -> Cmd msg
post_toggle_title (QuizTitle attrs) =
  selectAllInputText attrs.id

init_quiz_fields : QuizFields
init_quiz_fields =
  QuizFields
  (QuizTitle ({
        id="quiz_title"
      , editable=False
      , error_string=""
      , error=False
      , name="title"
      , index=0 }))
  (QuizIntro ({
        id="quiz_introduction"
      , editable=False
      , error_string=""
      , error=False
      , name="introduction"
      , index=2 }))
  (QuizTags ({
        id="quiz_tags"
      , editable=False
      , error_string=""
      , error=False
      , name="tags"
      , index=1 }))
