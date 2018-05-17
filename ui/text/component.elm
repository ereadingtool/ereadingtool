module Text.Component exposing (TextComponent, TextField(..), TextBodyFieldParams, emptyTextComponent, body, text, title
  , source, difficulty, author, question_fields, attributes, set_field, set_text, index, delete_question_field
  , set_answer, set_answer_text, set_question, switch_editable, add_new_question, toggle_question_menu, update_body
  , update_question_field, set_answer_correct, set_answer_feedback, text_field_id, editable, post_toggle_commands)

import Array exposing (Array)
import Field

import Text.Model exposing (Text, TextDifficulty)
import Question.Field exposing (QuestionField, generate_question_field)
import Answer.Field

import Ports exposing (ckEditor, CKEditorID, CKEditorText)

type alias TextFieldParams = Field.FieldAttributes { name : String }
type alias TextBodyFieldParams = Field.FieldAttributes { name : String, ckeditor_id : String }

type TextField =
    Title TextFieldParams
  | Source TextFieldParams
  | Difficulty TextFieldParams
  | Author TextFieldParams
  | Body TextBodyFieldParams

type alias TextFields = {
    title: TextField
  , source: TextField
  , difficulty: TextField
  , author: TextField
  , body: TextField }

type alias TextComponentAttributes = { index: Int }

type TextComponent = TextComponent Text TextComponentAttributes TextFields (Array QuestionField)

type alias FieldName = String

generate_text_field_params : Int -> String -> TextFieldParams
generate_text_field_params i attr = {
    id=String.join "_" ["text", toString i, attr]
  , editable=False
  , error=False
  , name=attr
  , index=i }

generate_body_text_field : Int -> TextBodyFieldParams
generate_body_text_field i = let base_field=generate_text_field_params i "body" in {
    id=base_field.id
  , editable=base_field.editable
  , error=base_field.error
  , name=base_field.name
  , index=base_field.index
  , ckeditor_id="" }

emptyTextComponent : Int -> TextComponent
emptyTextComponent i = TextComponent Text.Model.emptyText { index=i } {
     title=Title (generate_text_field_params i "title")
  ,  source=Source (generate_text_field_params i "source")
  ,  difficulty=Difficulty (generate_text_field_params i "difficulty")
  ,  author=Author (generate_text_field_params i "author")
  ,  body=Body (generate_body_text_field i)
  } Question.Field.initial_question_fields

switch_editable : TextField -> TextField
switch_editable text_field =
  let
    switch params = { params | editable = (if params.editable then False else True) }
  in
    case text_field of
      Title params -> Title (switch params)
      Source params -> Source (switch params)
      Difficulty params -> Difficulty (switch params)
      Author params -> Author (switch params)
      Body params -> Body (switch params)

title : TextComponent -> TextField
title (TextComponent text attr fields question_fields) = fields.title

update_title : TextComponent -> String -> TextComponent
update_title (TextComponent text attr fields question_fields) title =
  TextComponent { text | title=title } attr fields question_fields

source : TextComponent -> TextField
source (TextComponent text attr fields question_fields) = fields.source

update_source : TextComponent -> String -> TextComponent
update_source (TextComponent text attr fields question_fields) source =
  TextComponent { text | source=source } attr fields question_fields

difficulty : TextComponent -> TextField
difficulty (TextComponent text attr fields question_fields) = fields.difficulty

update_difficulty : TextComponent -> String -> TextComponent
update_difficulty (TextComponent text attr fields question_fields) difficulty =
  TextComponent { text | difficulty=difficulty } attr fields question_fields

author : TextComponent -> TextField
author (TextComponent text attr fields question_fields) = fields.author

update_author : TextComponent -> String -> TextComponent
update_author (TextComponent text attr fields question_fields) author =
  TextComponent { text | author=author } attr fields question_fields

text_field_id : TextField -> String
text_field_id text_field =
  case text_field of
    Title params -> params.id
    Source params -> params.id
    Difficulty params -> params.id
    Body params -> params.id
    Author params -> params.id

editable : TextField -> Bool
editable text_field =
  case text_field of
    Title params -> params.editable
    Source params -> params.editable
    Difficulty params -> params.editable
    Body params -> params.editable
    Author params -> params.editable

post_toggle_commands : TextField -> List (Cmd msg)
post_toggle_commands text_field =
  case text_field of
      Body params -> [ckEditor params.id]
      _ -> [Cmd.none]

body : TextComponent -> TextField
body (TextComponent text attr fields question_fields) = fields.body

update_body : TextComponent -> String -> TextComponent
update_body (TextComponent text attr fields question_fields) body =
  TextComponent { text | body=body } attr fields question_fields

text : TextComponent -> Text
text (TextComponent text attr fields question_fields) = text

attributes : TextComponent -> TextComponentAttributes
attributes (TextComponent text attr fields question_fields) = attr

index : TextComponent -> Int
index text_component = let attrs = (attributes text_component) in attrs.index

set_question : TextComponent -> QuestionField -> TextComponent
set_question (TextComponent text attr fields question_fields) question_field =
  let
    question_index = Question.Field.index question_field
  in
    TextComponent text attr fields (Array.set question_index question_field question_fields)

set_answer : TextComponent -> Answer.Field.AnswerField -> TextComponent
set_answer (TextComponent text attr fields question_fields) answer_field =
  TextComponent text attr fields (Question.Field.set_answer_field question_fields answer_field)

set_answer_text : TextComponent -> Answer.Field.AnswerField -> String -> TextComponent
set_answer_text text_component answer_field answer_text =
  set_answer text_component (Answer.Field.set_answer_text answer_field answer_text)

set_answer_correct : TextComponent -> Answer.Field.AnswerField -> TextComponent
set_answer_correct text_component answer_field =
  case (Question.Field.question_field_for_answer (question_fields text_component) answer_field) of
    Just question_field ->
      set_question text_component (Question.Field.set_answer_correct question_field answer_field)
    _ -> text_component

set_answer_feedback : TextComponent -> Answer.Field.AnswerField -> String -> TextComponent
set_answer_feedback text_component answer_field feedback =
  case (Question.Field.question_field_for_answer (question_fields text_component) answer_field) of
    Just question_field ->
      set_question text_component (Question.Field.set_answer_feedback question_field answer_field feedback)
    _ -> text_component

set_text : TextComponent -> FieldName -> String -> TextComponent
set_text (TextComponent text attr fields question_fields) field_name value =
  case field_name of
    "title" -> TextComponent { text | title=value } attr fields question_fields
    "source" -> TextComponent { text | source=value } attr fields question_fields
    "difficulty" -> TextComponent { text | difficulty=value }  attr fields question_fields
    "author" -> TextComponent { text | author=value }  attr fields question_fields
    "body" -> TextComponent { text | body=value }  attr fields question_fields
    _ -> (TextComponent text attr fields question_fields)

set_field : TextComponent -> TextField -> TextComponent
set_field (TextComponent text attr fields question_fields) new_text_field =
  case new_text_field of
    Title params -> TextComponent text attr { fields | title = Title params } question_fields
    Source params -> TextComponent text attr { fields | source = Source params } question_fields
    Difficulty params -> TextComponent text attr { fields | difficulty = Difficulty params } question_fields
    Author params -> TextComponent text attr { fields | author = Author params } question_fields
    Body params -> TextComponent text attr { fields | body = Body params } question_fields

set_body_field : TextComponent -> TextBodyFieldParams -> TextComponent
set_body_field (TextComponent text attr fields question_fields) new_body_params =
  TextComponent text attr { fields | body = Body new_body_params } question_fields

question_fields : TextComponent -> Array QuestionField
question_fields (TextComponent text attr fields question_fields) = question_fields

update_question_field : TextComponent -> QuestionField -> TextComponent
update_question_field (TextComponent text attr fields question_fields) question_field =
    (TextComponent text attr fields (Question.Field.update_question_field question_field question_fields))

delete_question_field : TextComponent -> QuestionField -> TextComponent
delete_question_field (TextComponent text attr fields question_fields) question_field =
    (TextComponent text attr fields (Question.Field.delete_question_field question_field question_fields))

add_new_question : TextComponent -> TextComponent
add_new_question (TextComponent text attr fields question_fields) =
  (Question.Field.add_new_question question_fields |> TextComponent text attr fields)

toggle_question_menu : TextComponent -> QuestionField -> TextComponent
toggle_question_menu text_component question_field =  let
    visible = if (Question.Field.menu_visible question_field) then False else True
  in
    set_question text_component (Question.Field.set_menu_visible question_field visible)
