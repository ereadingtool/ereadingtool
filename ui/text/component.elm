module Text.Component exposing (TextComponent, TextField, emptyTextComponent, body, text, title, source
  , difficulty, author, question_fields, attributes, set_field, set_text, index, delete_question_field
  , set_answer, set_question, switch_editable, add_new_question, toggle_question_menu, update_question_field)

import Array exposing (Array)
import Field

import Text.Model exposing (Text, TextDifficulty)
import Question.Field exposing (QuestionField, generate_question_field)
import Answer.Field

type alias TextField = {
    id : String
  , editable : Bool
  , error : Bool
  , name : String
  , index : Int }

type alias TextFields = {
    title: Field.FieldAttributes TextField
  , source: Field.FieldAttributes TextField
  , difficulty: Field.FieldAttributes TextField
  , author: Field.FieldAttributes TextField
  , body: Field.FieldAttributes TextField }

type alias TextComponentAttributes = { index: Int }

type TextComponent = TextComponent Text TextComponentAttributes TextFields (Array QuestionField)

type alias FieldName = String

generate_text_field : Int -> String -> TextField
generate_text_field i attr = {
    id=String.join "_" ["text", toString i, attr]
  , editable=False
  , error=False
  , name=attr
  , index=i }

emptyTextComponent : Int -> TextComponent
emptyTextComponent i = TextComponent Text.Model.emptyText { index=i } {
     title=generate_text_field i "title"
  ,  source=generate_text_field i "source"
  ,  difficulty=generate_text_field i "difficulty"
  ,  author=generate_text_field i "author"
  ,  body=generate_text_field i "body"
  } Question.Field.initial_question_fields

switch_editable : TextField -> TextField
switch_editable field = { field | editable = (if field.editable then False else True) }

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

set_text : TextComponent -> FieldName -> String -> TextComponent
set_text (TextComponent text attr fields question_fields) field_name value =
  case field_name of
    "title" -> TextComponent { text | title=value } attr fields question_fields
    "source" -> TextComponent { text | source=value } attr fields question_fields
    "difficulty" -> TextComponent { text | difficulty=value }  attr fields question_fields
    "author" -> TextComponent { text | author=value }  attr fields question_fields
    "body" -> TextComponent { text | body=value }  attr fields question_fields
    _ -> (TextComponent text attr fields question_fields)

set_field : TextComponent -> TextField -> FieldName -> TextComponent
set_field (TextComponent text attr fields question_fields) new_text_field field_name =
  case field_name of
    "title" -> TextComponent text attr { fields | title = new_text_field } question_fields
    "source" -> TextComponent text attr { fields | source = new_text_field } question_fields
    "difficulty" -> TextComponent text attr { fields | difficulty = new_text_field } question_fields
    "author" -> TextComponent text attr { fields | author = new_text_field } question_fields
    "body" -> TextComponent text attr { fields | body = new_text_field } question_fields
    _ -> (TextComponent text attr fields question_fields)

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
