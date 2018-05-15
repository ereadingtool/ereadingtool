module Question.Field exposing (QuestionField, QuestionType(..), generate_question_field, update_question_field
  , add_new_question, delete_question, initial_question_fields, attributes, index, set_hover, switch_editable
  , set_question_type, question, menu_visible, id, error, hover, editable, answers, set_menu_visible
  , update_question, set_question_body, set_answer_field, delete_question_field)

import Question.Model exposing (Question)

import Answer.Field exposing (AnswerField, generate_answer_field)

import Array exposing (Array)
import Field

type alias QuestionFieldAttributes = {
    id: String
  , editable: Bool
  , hover: Bool
  , menu_visible: Bool
  , error: Bool
  , index: Int }

type QuestionType = MainIdea | Detail

type QuestionField = QuestionField Question (Field.FieldAttributes (QuestionFieldAttributes)) (Array AnswerField)

generate_question_field : Int -> Question -> QuestionField
generate_question_field i question = QuestionField question {
    id = (String.join "_" ["question", toString i])
  , editable = False
  , hover = False
  , menu_visible = False
  , error = False
  , index = i } (Array.indexedMap (Answer.Field.generate_answer_field i) question.answers)

add_new_question : Array QuestionField -> Array QuestionField
add_new_question fields = let arr_len = Array.length fields in
  Array.push (generate_question_field arr_len (Question.Model.new_question arr_len)) fields

set_answer_field : Array QuestionField -> AnswerField -> Array QuestionField
set_answer_field question_fields answer_field =
  let
    question_index = Answer.Field.question_index answer_field
    answer_index = Answer.Field.index answer_field
  in
    case (Array.get question_index question_fields) of
      Just (QuestionField question attr answers) ->
        Array.set question_index (QuestionField question attr (Array.set answer_index answer_field answers)) question_fields
      _ ->
        question_fields

question_index : QuestionField -> Int
question_index (QuestionField _ attr _) = attr.index

question : QuestionField -> Question
question (QuestionField question _ _) = question

update_question : QuestionField -> Question -> QuestionField
update_question (QuestionField question attr answers) new_question =
  QuestionField new_question attr answers

error : QuestionField -> Bool
error question_field = let attrs = (attributes question_field) in attrs.error

delete_question : Int -> Array QuestionField -> Array QuestionField
delete_question index fields =
     Array.indexedMap (\i (QuestionField question attr answer_fields) ->
        QuestionField question { attr | index = i }
        (Array.map (\answer_field -> Answer.Field.update_question_index answer_field i) answer_fields)
     ) <| Array.filter (\field -> (question_index field) /= index) fields

update_question_field : QuestionField -> Array QuestionField -> Array QuestionField
update_question_field new_question_field question_fields =
  Array.set (question_index new_question_field) new_question_field question_fields

initial_question_fields : Array QuestionField
initial_question_fields = (Array.indexedMap generate_question_field Question.Model.initial_questions)

set_question_type : QuestionField -> QuestionType -> QuestionField
set_question_type (QuestionField question attr answer_fields) question_type =
  let
    q_type = (case question_type of
      MainIdea -> "main_idea"
      Detail -> "detail")
  in
    QuestionField { question | question_type = q_type } attr answer_fields

switch_editable : QuestionField -> QuestionField
switch_editable (QuestionField question attr answer_fields) =
  QuestionField question { attr | editable = (if attr.editable then False else True), hover=False } answer_fields

menu_visible : QuestionField -> Bool
menu_visible question_field = let attrs = (attributes question_field) in attrs.menu_visible

set_question_body : QuestionField -> String -> QuestionField
set_question_body (QuestionField question attr answer_fields) value =
  QuestionField { question | body = value } attr answer_fields

set_hover : QuestionField -> Bool -> QuestionField
set_hover (QuestionField question attr answer_fields) hover =
  QuestionField question { attr | hover = hover } answer_fields

set_menu_visible : QuestionField -> Bool -> QuestionField
set_menu_visible (QuestionField question attr answer_fields) visible =
  QuestionField question { attr | menu_visible = visible } answer_fields

attributes : QuestionField -> QuestionFieldAttributes
attributes (QuestionField question attr answer_fields) = attr

delete_question_field : QuestionField -> Array QuestionField -> Array QuestionField
delete_question_field question_field question_fields = (index >> delete_question) question_field question_fields

index : QuestionField -> Int
index question_field = let attrs = (attributes question_field) in attrs.index

id : QuestionField -> String
id question_field = let attrs = (attributes question_field) in attrs.id

hover : QuestionField -> Bool
hover question_field = let attrs = (attributes question_field) in attrs.hover

editable : QuestionField -> Bool
editable question_field = let attrs = (attributes question_field) in attrs.editable

answers : QuestionField -> Array AnswerField
answers (QuestionField _ _ answer_fields) = answer_fields
