module Answer.Field exposing (AnswerField, AnswerFeedbackField, generate_answer_field, update_question_index
  , index, question_index, switch_editable, editable, answer, attributes, error, id, name, feedback_field
  , set_answer_text, set_answer_correct, set_answer_feedback, toAnswers, get_answer_field, update_feedback_error
  , update_error)

import Field
import Array exposing (Array)

import Answer.Model exposing (Answer)

type alias AnswerFeedbackField = {
    id: String
  , editable: Bool
  , error_string: String
  , error: Bool }

type alias AnswerFieldAttributes = {
    id: String
  , name: String
  , editable: Bool
  , error: Bool
  , error_string: String
  , question_index: Int
  , index: Int }

type AnswerField = AnswerField Answer (Field.FieldAttributes AnswerFieldAttributes) AnswerFeedbackField

update_question_index : AnswerField -> Int -> AnswerField
update_question_index (AnswerField answer attr feedback) i = AnswerField answer { attr | question_index = i} feedback

generate_answer_feedback_field : String -> AnswerFeedbackField
generate_answer_feedback_field id = {
    id = id
  , editable = False
  , error_string = ""
  , error = False }

generate_answer_field : Int -> Int -> Int -> Answer -> AnswerField
generate_answer_field i j k answer =
  let
    answer_id = String.join "_" ["textsection", toString i, "question", toString j, "answer", toString k]
    answer_name = String.join "_" ["textsection", toString i, "question", toString j, "correct_answer"]
  in
    AnswerField answer {
      id = answer_id
    , name = answer_name
    , editable = False
    , error = False
    , error_string = ""
    , question_index = j
    , index = k } (generate_answer_feedback_field <| String.join "_" [answer_id, "feedback"])

toAnswers : Array AnswerField -> Array Answer
toAnswers answer_fields = Array.map answer answer_fields

feedback_field : AnswerField -> AnswerFeedbackField
feedback_field (AnswerField _ _ feedback_field) = feedback_field

attributes : AnswerField -> Field.FieldAttributes AnswerFieldAttributes
attributes (AnswerField answer attr feedback_field) = attr

name : AnswerField -> String
name answer_field = let attrs = (attributes answer_field) in attrs.name

id : AnswerField -> String
id answer_field = let attrs = (attributes answer_field) in attrs.id

error : AnswerField -> Bool
error answer_field = let attrs = (attributes answer_field) in attrs.error

index : AnswerField -> Int
index answer_field = let attrs = (attributes answer_field) in attrs.index

answer : AnswerField -> Answer
answer (AnswerField answer _ _) = answer

switch_editable : AnswerField -> AnswerField
switch_editable (AnswerField answer attr feedback) =
  AnswerField answer { attr | editable = (if attr.editable then False else True) } feedback

set_answer_text : AnswerField -> String -> AnswerField
set_answer_text (AnswerField answer attr feedback) text =
  AnswerField { answer | text = text } attr feedback

set_answer_correct : AnswerField -> Bool -> AnswerField
set_answer_correct (AnswerField answer attr feedback) correct =
  AnswerField { answer | correct = correct } attr feedback

set_answer_feedback : AnswerField -> String -> AnswerField
set_answer_feedback (AnswerField answer attr feedback) new_feedback =
      AnswerField { answer | feedback = new_feedback } attr feedback

editable : AnswerField -> Bool
editable answer_field = let attrs = (attributes answer_field) in attrs.editable

question_index : AnswerField -> Int
question_index answer_field = let attrs = (attributes answer_field) in attrs.question_index

get_answer_field : Array AnswerField -> Int -> Maybe AnswerField
get_answer_field answer_fields index =
  Array.get index answer_fields

update_error : AnswerField -> String -> AnswerField
update_error (AnswerField answer attr feedback) error_string =
  AnswerField answer { attr | error = True, error_string = error_string } feedback

update_feedback_error : AnswerField -> String -> AnswerField
update_feedback_error (AnswerField answer attr feedback) error_string =
  switch_editable (AnswerField answer attr { feedback | error = True, error_string = error_string })