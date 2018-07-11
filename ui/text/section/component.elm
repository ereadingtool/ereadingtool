module Text.Section.Component exposing (TextSectionComponent, TextField, emptyTextSectionComponent, body, text
  , question_fields, attributes, set_field, set_text, index, delete_question_field, fromTextSection
  , set_answer, set_answer_text, set_question, switch_editable, add_new_question, toggle_question_menu, update_body
  , update_question_field, set_answer_correct, set_answer_feedback, text_field_id, editable, toTextSection
  , post_toggle_commands, reinitialize_ck_editor, update_errors, delete_selected_question_fields, set_index)

import Array exposing (Array)
import Field

import Text.Model exposing (new_text)
import Text.Section.Model exposing (TextSection)
import Question.Field exposing (QuestionField, generate_question_field)
import Answer.Field

import Ports exposing (ckEditor, ckEditorSetHtml, CKEditorID, CKEditorText)

type alias TextField = Field.FieldAttributes { name : String }

type alias TextFields = { body: TextField }

type alias TextSectionComponentAttributes = { index: Int }

type TextSectionComponent = TextSectionComponent TextSection TextSectionComponentAttributes TextFields (Array QuestionField)

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

fromTextSection : Int -> TextSection -> TextSectionComponent
fromTextSection i text_section =
  TextSectionComponent text_section { index=i } (generate_text_fields i) (Question.Field.fromQuestions i text_section.questions)

text_section : TextSectionComponent -> TextSection
text_section (TextSectionComponent text_section _ _ _) = text_section

reinitialize_ck_editor : TextSectionComponent -> Cmd msg
reinitialize_ck_editor text_section_component =
 let
   t = text_section text_section_component
   body_field = body text_section_component
 in
   Cmd.batch [ckEditor body_field.id, ckEditorSetHtml (body_field.id, t.body)]

emptyTextSectionComponent : Int -> TextSectionComponent
emptyTextSectionComponent i =
  TextSectionComponent Text.Model.new_text { index=i } (generate_text_fields i) (Question.Field.initial_question_fields i)

switch_editable : TextField -> TextField
switch_editable text_field =
  let
    switch field = { field | editable = (if field.editable then False else True) }
  in
    switch text_field

update_errors : TextSectionComponent -> (String, String) -> TextSectionComponent
update_errors ((TextSectionComponent text attr fields question_fields) as text_component) (field_id, field_error) =
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
          TextSectionComponent text attr fields (Question.Field.update_errors question_fields (field_id, field_error))
      _ -> text_component -- empty key

text_field_id : TextField -> String
text_field_id text_field = text_field.id

editable : TextField -> Bool
editable text_field = text_field.editable

post_toggle_commands : TextField -> List (Cmd msg)
post_toggle_commands text_field =
  case text_field.name of
      "body" -> [ckEditor text_field.id]
      _ -> [Cmd.none]

body : TextSectionComponent -> TextField
body (TextSectionComponent text attr fields question_fields) = fields.body

update_body : TextSectionComponent -> String -> TextSectionComponent
update_body (TextSectionComponent text attr fields question_fields) body =
  TextSectionComponent { text | body=body } attr fields question_fields

{-text : TextSectionComponent -> Text
text (TextSectionComponent text attr fields question_fields) = text-}

attributes : TextSectionComponent -> TextSectionComponentAttributes
attributes (TextSectionComponent text attr fields question_fields) = attr

index : TextSectionComponent -> Int
index text_component = let attrs = (attributes text_component) in attrs.index

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
set_answer_text text_component answer_field answer_text =
  set_answer text_component (Answer.Field.set_answer_text answer_field answer_text)

set_answer_correct : TextSectionComponent -> Answer.Field.AnswerField -> TextSectionComponent
set_answer_correct text_component answer_field =
  case (Question.Field.question_field_for_answer (question_fields text_component) answer_field) of
    Just question_field ->
      set_question text_component (Question.Field.set_answer_correct question_field answer_field)
    _ -> text_component

set_answer_feedback : TextSectionComponent -> Answer.Field.AnswerField -> String -> TextSectionComponent
set_answer_feedback text_component answer_field feedback =
  case (Question.Field.question_field_for_answer (question_fields text_component) answer_field) of
    Just question_field ->
      set_question text_component (Question.Field.set_answer_feedback question_field answer_field feedback)
    _ -> text_component

update_field_error : TextField -> String -> TextField
update_field_error text_field error_string =
  { text_field | error = True, error_string = error_string }

{-get_field : TextSectionComponent -> FieldName -> Maybe TextField
get_field (TextSectionComponent text attr fields question_fields) field_name =
  case field_name of
    "title" -> Just fields.title
    "source" -> Just fields.source
    "difficulty" -> Just fields.difficulty
    "author" -> Just fields.author
    "body" -> Just fields.body
    _ -> Nothing

set_field : TextSectionComponent -> TextField -> TextSectionComponent
set_field ((TextSectionComponent text attr fields question_fields) as text_component) new_text_field =
  case new_text_field.name of
    "title" -> TextSectionComponent text attr { fields | title = new_text_field } question_fields
    "source" -> TextSectionComponent text attr { fields | source = new_text_field } question_fields
    "difficulty" -> TextSectionComponent text attr { fields | difficulty = new_text_field } question_fields
    "author" -> TextSectionComponent text attr { fields | author = new_text_field } question_fields
    "body" -> TextSectionComponent text attr { fields | body = new_text_field } question_fields
    _ -> text_component-}

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
toggle_question_menu text_component question_field =  let
    visible = if (Question.Field.menu_visible question_field) then False else True
  in
    set_question text_component (Question.Field.set_menu_visible question_field visible)

toTextSection : TextSectionComponent -> TextSection
toTextSection text_section_component =
  let
    new_text_section = text_section text_section_component
    questions = Question.Field.toQuestions (question_fields text_section_component)
  in
    { new_text_section | questions = questions }
