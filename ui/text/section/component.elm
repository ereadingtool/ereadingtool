module Text.Section.Component exposing (TextSectionComponent, TextSectionField, emptyTextSectionComponent, body, text_section
  , question_fields, attributes, set_field, set_field_value, index, delete_question_field
  , set_answer, set_answer_text, set_question, switch_editable, add_new_question, toggle_question_menu, update_body
  , update_question_field, set_answer_correct, set_answer_feedback, text_field_id, editable, toTextSection
  , fromTextSection, post_toggle_commands, reinitialize_ck_editor, update_errors, delete_selected_question_fields
  , set_index, delete_answer)

import Array exposing (Array)
import Field

import Text.Section.Model exposing (TextSection)

import Question.Field exposing (QuestionField, generate_question_field)
import Answer.Field

import Ports exposing (ckEditor, ckEditorSetHtml, CKEditorID, CKEditorText)

type alias TextSectionField = Field.FieldAttributes { name : String }

type alias TextSectionFields = { body: TextSectionField }

type alias TextSectionComponentAttributes = { index: Int }

type TextSectionComponent = TextSectionComponent
  TextSection TextSectionComponentAttributes TextSectionFields (Array QuestionField)

type alias FieldName = String

generate_text_section_field_params : Int -> String -> TextSectionField
generate_text_section_field_params i attr = {
    id=String.join "_" ["textsection", toString i, attr]
  , editable=False
  , error_string=""
  , error=False
  , name=attr
  , index=i }

generate_text_section_fields : Int -> TextSectionFields
generate_text_section_fields i = { body=(generate_text_section_field_params i "body") }

fromTextSection : Int -> TextSection -> TextSectionComponent
fromTextSection i text =
  TextSectionComponent text { index=i } (generate_text_section_fields i) (Question.Field.fromQuestions i text.questions)

reinitialize_ck_editor : TextSectionComponent -> Cmd msg
reinitialize_ck_editor text_section_component =
 let
   t = text_section text_section_component
   body_field = body text_section_component
 in
   Cmd.batch [ckEditor body_field.id, ckEditorSetHtml (body_field.id, t.body)]

emptyTextSectionComponent : Int -> TextSectionComponent
emptyTextSectionComponent i =
  TextSectionComponent
    Text.Section.Model.emptyTextSection
    { index=i }
    (generate_text_section_fields i)
    (Question.Field.initial_question_fields i)

switch_editable : TextSectionField -> TextSectionField
switch_editable text_field =
  let
    switch field = { field | editable = (if field.editable then False else True) }
  in
    switch text_field

update_errors : TextSectionComponent -> (String, String) -> TextSectionComponent
update_errors ((TextSectionComponent text attr fields question_fields) as text_section) (field_id, field_error) =
  {- error keys could be
       body
    || (question_i_answer_j)
    || (question_i_answer_j_feedback) -}
  let
    error_key = String.split "_" field_id
    first_key = List.head error_key
  in
    case first_key of
      Just fst ->
        if List.member fst ["body"] then
          case get_field text_section fst of
            Just field ->
              set_field text_section (update_field_error field field_error)
            Nothing ->
              text_section -- no matching field name
        else -- update questions/answers errors
          TextSectionComponent text attr fields (Question.Field.update_errors question_fields (field_id, field_error))
      _ -> text_section -- empty key

text_field_id : TextSectionField -> String
text_field_id text_field = text_field.id

editable : TextSectionField -> Bool
editable text_field = text_field.editable

post_toggle_commands : TextSectionField -> List (Cmd msg)
post_toggle_commands text_field =
  case text_field.name of
      "body" -> [ckEditor text_field.id]
      _ -> [Cmd.none]

body : TextSectionComponent -> TextSectionField
body (TextSectionComponent text attr fields question_fields) = fields.body

update_body : TextSectionComponent -> String -> TextSectionComponent
update_body (TextSectionComponent text attr fields question_fields) body =
  TextSectionComponent { text | body=body } attr fields question_fields

text_section : TextSectionComponent -> TextSection
text_section (TextSectionComponent text_section attr fields question_fields) = text_section

attributes : TextSectionComponent -> TextSectionComponentAttributes
attributes (TextSectionComponent text attr fields question_fields) = attr

index : TextSectionComponent -> Int
index text_section = let attrs = (attributes text_section) in attrs.index

set_index : TextSectionComponent -> Int -> TextSectionComponent
set_index (TextSectionComponent text attr fields question_fields) index =
  TextSectionComponent text { attr | index = index } fields question_fields

set_question : TextSectionComponent -> QuestionField -> TextSectionComponent
set_question (TextSectionComponent text attr fields question_fields) question_field =
  let
    question_index = Question.Field.index question_field
  in
    TextSectionComponent text attr fields (Array.set question_index question_field question_fields)

set_answer : TextSectionComponent -> Answer.Field.AnswerField -> TextSectionComponent
set_answer (TextSectionComponent text attr fields question_fields) answer_field =
  TextSectionComponent text attr fields (Question.Field.set_answer_field question_fields answer_field)

set_answer_text : TextSectionComponent -> Answer.Field.AnswerField -> String -> TextSectionComponent
set_answer_text text_section answer_field answer_text =
  set_answer text_section (Answer.Field.set_answer_text answer_field answer_text)

set_answer_correct : TextSectionComponent -> Answer.Field.AnswerField -> TextSectionComponent
set_answer_correct text_section answer_field =
  case (Question.Field.question_field_for_answer (question_fields text_section) answer_field) of
    Just question_field ->
      set_question text_section (Question.Field.set_answer_correct question_field answer_field)
    _ -> text_section

set_answer_feedback : TextSectionComponent -> Answer.Field.AnswerField -> String -> TextSectionComponent
set_answer_feedback text_section answer_field feedback =
  case (Question.Field.question_field_for_answer (question_fields text_section) answer_field) of
    Just question_field ->
      set_question text_section (Question.Field.set_answer_feedback question_field answer_field feedback)
    _ -> text_section

delete_answer : TextSectionComponent -> Answer.Field.AnswerField -> TextSectionComponent
delete_answer (TextSectionComponent text attr fields question_fields) answer_field =
  let
    question_field = Answer.Field.question_index
  in
    TextSectionComponent text attr fields question_fields

set_field_value : TextSectionComponent -> FieldName -> String -> TextSectionComponent
set_field_value (TextSectionComponent text attr fields question_fields) field_name value =
  case field_name of
    "body" -> TextSectionComponent { text | body=value }  attr fields question_fields
    _ -> (TextSectionComponent text attr fields question_fields)

update_field_error : TextSectionField -> String -> TextSectionField
update_field_error text_field error_string =
  { text_field | editable=True, error = True, error_string = error_string }

get_field : TextSectionComponent -> FieldName -> Maybe TextSectionField
get_field (TextSectionComponent text attr fields question_fields) field_name =
  case field_name of
    "body" -> Just fields.body
    _ -> Nothing

set_field : TextSectionComponent -> TextSectionField -> TextSectionComponent
set_field ((TextSectionComponent text attr fields question_fields) as text_section) new_text_field =
  case new_text_field.name of
    "body" -> TextSectionComponent text attr { fields | body = new_text_field } question_fields
    _ -> text_section

question_fields : TextSectionComponent -> Array QuestionField
question_fields (TextSectionComponent text attr fields question_fields) = question_fields

update_question_field : TextSectionComponent -> QuestionField -> TextSectionComponent
update_question_field (TextSectionComponent text attr fields question_fields) question_field =
  TextSectionComponent text attr fields (Question.Field.update_question_field question_field question_fields)

delete_question_field : TextSectionComponent -> QuestionField -> TextSectionComponent
delete_question_field (TextSectionComponent text attr fields question_fields) question_field =
  TextSectionComponent text attr fields (Question.Field.delete_question_field question_field question_fields)

delete_selected_question_fields : TextSectionComponent -> TextSectionComponent
delete_selected_question_fields (TextSectionComponent text attr fields question_fields) =
  TextSectionComponent text attr fields (Question.Field.delete_selected question_fields)

add_new_question : TextSectionComponent -> TextSectionComponent
add_new_question (TextSectionComponent text attr fields question_fields) =
  TextSectionComponent text attr fields (Question.Field.add_new_question attr.index question_fields)

toggle_question_menu : TextSectionComponent -> QuestionField -> TextSectionComponent
toggle_question_menu text_section question_field =  let
    visible = if (Question.Field.menu_visible question_field) then False else True
  in
    set_question text_section (Question.Field.set_menu_visible question_field visible)

toTextSection : TextSectionComponent -> TextSection
toTextSection text_section_component =
  let
    new_text_section = text_section text_section_component
    questions = Question.Field.toQuestions (question_fields text_section_component)
  in
    { new_text_section | questions = questions }
