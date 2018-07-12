module Quiz.Field exposing (..)

import Field

import Ports exposing (ckEditor, ckEditorSetHtml, CKEditorID, CKEditorText, addClassToCKEditor, selectAllInputText)

type alias QuizFieldAttributes = (Field.FieldAttributes { name: String })

type QuizTitle = QuizTitle QuizFieldAttributes
type QuizIntro = QuizIntro QuizFieldAttributes
type QuizTags = QuizTags QuizFieldAttributes
type TextAuthor = TextAuthor QuizFieldAttributes
type TextSource = TextSource QuizFieldAttributes
type TextDifficulty = TextDifficulty QuizFieldAttributes

type QuizFields = QuizFields QuizTitle QuizIntro QuizTags TextAuthor TextSource TextDifficulty


title : QuizFields -> QuizTitle
title (QuizFields quiz_title _ _ _ _ _) =
  quiz_title

intro : QuizFields -> QuizIntro
intro (QuizFields _ quiz_intro _ _ _ _) =
  quiz_intro

tags : QuizFields -> QuizTags
tags (QuizFields _ _ quiz_tags _ _ _) =
  quiz_tags

author : QuizFields -> TextAuthor
author (QuizFields _ _ _ text_author _ _) =
  text_author

source : QuizFields -> TextSource
source (QuizFields _ _ _ _ text_source _) =
  text_source

difficulty : QuizFields -> TextDifficulty
difficulty (QuizFields _ _ _ _ _ text_difficulty) =
  text_difficulty

set_intro : QuizFields -> QuizFieldAttributes -> QuizFields
set_intro (QuizFields quiz_title _ quiz_tags text_author text_source text_difficulty) field_attrs =
  QuizFields quiz_title (QuizIntro field_attrs) quiz_tags text_author text_source text_difficulty

set_title : QuizFields -> QuizFieldAttributes -> QuizFields
set_title (QuizFields _ quiz_intro quiz_tags text_author text_source text_difficulty) field_attrs =
  QuizFields (QuizTitle field_attrs) quiz_intro quiz_tags text_author text_source text_difficulty

set_author : QuizFields -> QuizFieldAttributes -> QuizFields
set_author (QuizFields text_title text_intro text_tags text_author text_source text_difficulty) field_attrs =
  QuizFields text_title text_intro text_tags (TextAuthor field_attrs) text_source text_difficulty

set_source : QuizFields -> QuizFieldAttributes -> QuizFields
set_source (QuizFields text_title text_intro text_tags text_author text_source text_difficulty) field_attrs =
  QuizFields text_title text_intro text_tags text_author (TextSource field_attrs) text_difficulty

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

post_toggle_intro : QuizIntro -> Cmd msg
post_toggle_intro (QuizIntro attrs) =
  Cmd.batch [ckEditor attrs.id, addClassToCKEditor (attrs.id, "quiz_introduction")]

post_toggle_title : QuizTitle -> Cmd msg
post_toggle_title (QuizTitle attrs) =
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


