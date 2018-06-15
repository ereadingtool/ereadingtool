module Text.Component exposing (TextComponent, TextField, emptyTextComponent, body, text, title
  , source, difficulty, author, question_fields, attributes, set_field, set_text, index, delete_question_field
  , set_answer, set_answer_text, set_question, switch_editable, add_new_question, toggle_question_menu, update_body
  , update_question_field, set_answer_correct, set_answer_feedback, text_field_id, editable, toText, fromText
  , post_toggle_commands, reinitialize_ck_editor, update_errors, delete_selected_question_fields)

import Array exposing (Array)
import Field

import Text.Model exposing (Text, TextDifficulty)
import Question.Field exposing (QuestionField, generate_question_field)
import Answer.Field

import Ports exposing (ckEditor, ckEditorSetHtml, CKEditorID, CKEditorText)

type alias TextField = Field.FieldAttributes { name : String }


type alias TextFields = {
    title: TextField
  , source: TextField
  , difficulty: TextField
  , author: TextField
  , body: TextField }

type alias TextComponentAttributes = { index: Int }

type TextComponent = TextComponent Text TextComponentAttributes TextFields (Array QuestionField)

type alias FieldName = String

generate_text_field_params : Int -> String -> TextField
generate_text_field_params i attr = {
    id=String.join "_" ["text", toString i, attr]
  , editable=False
  , error_string=""
  , error=False
  , name=attr
  , index=i }


generate_text_fields : Int -> TextFields
generate_text_fields i = {
     title=(generate_text_field_params i "title")
  ,  source=(generate_text_field_params i "source")
  ,  difficulty=(generate_text_field_params i "difficulty")
  ,  author=(generate_text_field_params i "author")
  ,  body=(generate_text_field_params i "body")
  }

fromText : Int -> Text -> TextComponent
fromText i text =
  TextComponent text { index=i } (generate_text_fields i) (Question.Field.fromQuestions i text.questions)

reinitialize_ck_editor : TextComponent -> Cmd msg
reinitialize_ck_editor text_component =
 let
   t = text text_component
   body_field = body text_component
 in
   Cmd.batch [ckEditor body_field.id, ckEditorSetHtml (body_field.id, t.body)]

emptyTextComponent : Int -> TextComponent
emptyTextComponent i =
  TextComponent Text.Model.emptyText { index=i } (generate_text_fields i) (Question.Field.initial_question_fields i)

switch_editable : TextField -> TextField
switch_editable text_field =
  let
    switch field = { field | editable = (if field.editable then False else True) }
  in
    switch text_field

title : TextComponent -> TextField
title (TextComponent text attr fields question_fields) = fields.title

update_errors : TextComponent -> (String, String) -> TextComponent
update_errors ((TextComponent text attr fields question_fields) as text_component) (field_id, field_error) =
  {- error keys could be
       (title|source|difficulty|author|body)
    || (question_i_answer_j)
    || (question_i_answer_j_feedback) -}
  let
    error_key = String.split "_" field_id
    first_key = List.head error_key
  in
    case first_key of
      Just fst ->
        if List.member fst ["title", "source", "difficulty", "author", "body"] then
          case get_field text_component fst of
            Just field ->
              set_field text_component (update_field_error field field_error)
            Nothing ->
              text_component -- no matching field name
        else -- update questions/answers errors
          TextComponent text attr fields (Question.Field.update_errors question_fields (field_id, field_error))
      _ -> text_component -- empty key

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
text_field_id text_field = text_field.id

editable : TextField -> Bool
editable text_field = text_field.editable

post_toggle_commands : TextField -> List (Cmd msg)
post_toggle_commands text_field =
  case text_field.name of
      "body" -> [ckEditor text_field.id]
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

update_field_error : TextField -> String -> TextField
update_field_error text_field error_string =
  { text_field | error = True, error_string = error_string }

get_field : TextComponent -> FieldName -> Maybe TextField
get_field (TextComponent text attr fields question_fields) field_name =
  case field_name of
    "title" -> Just fields.title
    "source" -> Just fields.source
    "difficulty" -> Just fields.difficulty
    "author" -> Just fields.author
    "body" -> Just fields.body
    _ -> Nothing

set_field : TextComponent -> TextField -> TextComponent
set_field ((TextComponent text attr fields question_fields) as text_component) new_text_field =
  case new_text_field.name of
    "title" -> TextComponent text attr { fields | title = new_text_field } question_fields
    "source" -> TextComponent text attr { fields | source = new_text_field } question_fields
    "difficulty" -> TextComponent text attr { fields | difficulty = new_text_field } question_fields
    "author" -> TextComponent text attr { fields | author = new_text_field } question_fields
    "body" -> TextComponent text attr { fields | body = new_text_field } question_fields
    _ -> text_component

question_fields : TextComponent -> Array QuestionField
question_fields (TextComponent text attr fields question_fields) = question_fields

update_question_field : TextComponent -> QuestionField -> TextComponent
update_question_field (TextComponent text attr fields question_fields) question_field =
  TextComponent text attr fields (Question.Field.update_question_field question_field question_fields)

delete_question_field : TextComponent -> QuestionField -> TextComponent
delete_question_field (TextComponent text attr fields question_fields) question_field =
  TextComponent text attr fields (Question.Field.delete_question_field question_field question_fields)

delete_selected_question_fields : TextComponent -> TextComponent
delete_selected_question_fields (TextComponent text attr fields question_fields) =
  TextComponent text attr fields (Question.Field.delete_selected question_fields)

add_new_question : TextComponent -> TextComponent
add_new_question (TextComponent text attr fields question_fields) =
  TextComponent text attr fields (Question.Field.add_new_question attr.index question_fields)

toggle_question_menu : TextComponent -> QuestionField -> TextComponent
toggle_question_menu text_component question_field =  let
    visible = if (Question.Field.menu_visible question_field) then False else True
  in
    set_question text_component (Question.Field.set_menu_visible question_field visible)

toText : TextComponent -> Text
toText text_component =
  let
    new_text = text text_component
    questions = Question.Field.toQuestions (question_fields text_component)
  in
    { new_text | questions = questions }
