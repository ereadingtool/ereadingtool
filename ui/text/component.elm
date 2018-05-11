module Text.Component exposing (TextComponent, TextField, emptyTextComponent, add_new_text, body, text, title, source
  , difficulty, author, update_errors, question_fields, attributes, set_field, set_text, index
  , set_answer, set_question, switch_editable)

import Array exposing (Array)
import Field
import Dict exposing (Dict)

import Text.Model exposing (Text, TextDifficulty)
import Question.Field exposing (QuestionField, generate_question_field)
import Answer.Field

type alias TextField = {
    id : String
  , editable : Bool
  , hover : Bool
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

generate_text_field : Int -> String -> TextField
generate_text_field i attr = {
    id=String.join "_" ["text", toString i, attr]
  , editable=False
  , hover=False
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

add_new_text : Array TextComponent -> Array TextComponent
add_new_text components = let arr_len = Array.length components in Array.push (emptyTextComponent arr_len) components

switch_editable : TextField -> TextField
switch_editable field = { field | editable = (if field.editable then False else True), hover = False }

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
  let
    answer_index = Answer.Field.index answer_field
    question_index = Answer.Field.question_index answer_field
  in
    case (Array.get question_index question_fields) of
     Just question_field -> TextComponent text attr fields (Array.set question_index question_field question_fields)
     _ -> TextComponent text attr fields question_fields

set_text : TextComponent -> String -> String -> TextComponent
set_text (TextComponent text attr fields question_fields) field_name value =
  case field_name of
    "title" -> TextComponent { text | title=value } attr fields question_fields
    "source" -> TextComponent { text | source=value } attr fields question_fields
    "difficulty" -> TextComponent { text | difficulty=value }  attr fields question_fields
    "author" -> TextComponent { text | author=value }  attr fields question_fields
    "body" -> TextComponent { text | body=value }  attr fields question_fields
    _ -> (TextComponent text attr fields question_fields)

set_field : TextComponent -> TextField -> String -> TextComponent
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

-- TODO: maps an error dictionary to a list of text components
update_errors : Array TextComponent -> (Dict String String) -> Array TextComponent
update_errors components errors = components