module Question.Field exposing (QuestionField, QuestionType(..), generate_question_field, update_question_field
  , add_new_question, delete_question, initial_question_fields, attributes, index, switch_editable, set_answer_feedback
  , set_question_type, question, menu_visible, id, error, editable, answers, set_menu_visible, set_answer_correct
  , update_question, set_question_body, set_answer_field, delete_question_field, question_field_for_answer
  , toQuestions, fromQuestions, update_errors, set_selected, delete_selected, get_question_field)

import Question.Model exposing (Question)

import Answer.Field exposing (AnswerField, generate_answer_field)

import Array exposing (Array)
import Field

type alias QuestionFieldAttributes = Field.FieldAttributes { menu_visible: Bool, selected: Bool }

type QuestionType = MainIdea | Detail

type QuestionField = QuestionField Question (Field.FieldAttributes QuestionFieldAttributes) (Array AnswerField)

toQuestions : Array QuestionField -> Array Question
toQuestions question_fields =
  Array.map toQuestion question_fields

toQuestion : QuestionField -> Question
toQuestion question_field =
  let
    new_question = question question_field
    new_answers = Answer.Field.toAnswers (answers question_field)
  in
    { new_question | answers = new_answers }

fromQuestions : Int -> Array Question -> Array QuestionField
fromQuestions text_index questions =
  Array.indexedMap (generate_question_field text_index) questions

generate_question_field : Int -> Int -> Question -> QuestionField
generate_question_field text_index question_index question =
  QuestionField question {
      id = (String.join "_" ["text", toString text_index, "question", toString question_index])
    , editable = False
    , menu_visible = False
    , selected = False
    , error_string = ""
    , error = False
    , index = question_index }
  (Array.indexedMap (Answer.Field.generate_answer_field text_index question_index) question.answers)

add_new_question : Int -> Array QuestionField -> Array QuestionField
add_new_question text_index fields =
  let
    new_question_index = Array.length fields
  in
    Array.push
      (generate_question_field text_index new_question_index (Question.Model.new_question new_question_index)) fields

update_error : QuestionField -> String -> QuestionField
update_error (QuestionField question attr answers) error_string =
  QuestionField question { attr | editable = True, error = True, error_string = error_string } answers

update_errors : Array QuestionField -> (String, String) -> Array QuestionField
update_errors question_fields (field_id, field_error) =
  let
    error_key = String.split "_" field_id
  in
    case error_key of
      "question" :: question_index :: "answer" :: answer_index :: feedback ->
        case String.toInt question_index of
          Ok i ->
            case String.toInt answer_index of
              Ok j ->
                case get_question_field question_fields i of
                  Just question_field ->
                    case Answer.Field.get_answer_field (answers question_field) j of
                      Just answer_field ->
                        set_answer_field question_fields
                          (if List.isEmpty feedback then
                            Answer.Field.update_error answer_field field_error
                          else
                            Answer.Field.update_feedback_error answer_field field_error)
                      Nothing -> question_fields -- answer field does not exist
                  Nothing ->
                    question_fields -- question field does not exist
              _ -> question_fields -- not a valid answer index
          _ -> question_fields -- not a valid question index
      "question" :: question_index :: "body" :: [] ->
        case String.toInt question_index of
           Ok i ->
             case get_question_field question_fields i of
               Just question_field ->
                 update_question_field (update_error question_field field_error) question_fields
               _ -> question_fields -- question field not present
           _ -> question_fields -- not a valid question index
      _ -> -- no matching error key

        question_fields

get_question_field : Array QuestionField -> Int -> Maybe QuestionField
get_question_field question_fields index =
  Array.get index question_fields

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

set_answer_feedback : QuestionField -> AnswerField -> String -> QuestionField
set_answer_feedback (QuestionField question attr answers) answer_field feedback =
  let
    index = Answer.Field.index answer_field
    new_answer_field = Answer.Field.set_answer_feedback answer_field feedback
  in
    (QuestionField question attr (Array.set index new_answer_field answers))

set_answer_correct : QuestionField -> AnswerField -> QuestionField
set_answer_correct (QuestionField question attr answers) answer_field =
  let
    answer_index = Answer.Field.index answer_field
    correct = Answer.Field.set_answer_correct
    index = Answer.Field.index
  in
    QuestionField question attr
      (Array.map (\a -> (if (index a) == answer_index then (correct a True) else (correct a False))) answers)


question_field_for_answer : Array QuestionField -> AnswerField -> Maybe QuestionField
question_field_for_answer question_fields answer_field =
  let
    question_index = Answer.Field.question_index answer_field
  in
    Array.get question_index question_fields

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

initial_question_fields : Int -> Array QuestionField
initial_question_fields text_index =
  (Array.indexedMap (generate_question_field text_index) Question.Model.initial_questions)

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
  QuestionField question { attr | editable = (if attr.editable then False else True) } answer_fields

menu_visible : QuestionField -> Bool
menu_visible question_field = let attrs = (attributes question_field) in attrs.menu_visible

set_question_body : QuestionField -> String -> QuestionField
set_question_body (QuestionField question attr answer_fields) value =
  QuestionField { question | body = value } attr answer_fields

set_menu_visible : QuestionField -> Bool -> QuestionField
set_menu_visible (QuestionField question attr answer_fields) visible =
  QuestionField question { attr | menu_visible = visible } answer_fields

set_selected : QuestionField -> Bool -> QuestionField
set_selected (QuestionField question attr answer_fields) selected =
  QuestionField question { attr | selected = selected } answer_fields

delete_selected : Array QuestionField -> Array QuestionField
delete_selected question_fields =
  Array.filter (\q ->
    let
      q_attrs = attributes q
    in
      not q_attrs.selected
  ) question_fields

attributes : QuestionField -> QuestionFieldAttributes
attributes (QuestionField question attr answer_fields) = attr

delete_question_field : QuestionField -> Array QuestionField -> Array QuestionField
delete_question_field question_field question_fields = (index >> delete_question) question_field question_fields

index : QuestionField -> Int
index question_field = let attrs = (attributes question_field) in attrs.index

id : QuestionField -> String
id question_field = let attrs = (attributes question_field) in attrs.id

editable : QuestionField -> Bool
editable question_field = let attrs = (attributes question_field) in attrs.editable

answers : QuestionField -> Array AnswerField
answers (QuestionField _ _ answer_fields) = answer_fields
