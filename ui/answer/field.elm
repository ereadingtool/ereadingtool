module Answer.Field exposing (AnswerField, AnswerFeedbackField, generate_answer_field, update_question_index)

import Field
import Answer.Model exposing (Answer)

type alias AnswerFeedbackField = {
    id : String
  , editable : Bool
  , error : Bool }

type alias AnswerFieldAttributes = {
    id: String
  , editable: Bool
  , hover: Bool
  , error: Bool
  , question_index: Int
  , index: Int }

type AnswerField = AnswerField Answer (Field.FieldAttributes AnswerFieldAttributes) AnswerFeedbackField

update_question_index : AnswerField -> Int -> AnswerField
update_question_index (AnswerField answer attr feedback) i = AnswerField answer { attr | question_index = i} feedback

generate_answer_feedback_field : String -> AnswerFeedbackField
generate_answer_feedback_field id = {
    id = id
  , editable = False
  , error = False }

generate_answer_field : Int -> Int -> Answer -> AnswerField
generate_answer_field i j answer = let
    answer_id = String.join "_" ["question", toString i, "answer", toString j]
  in
    AnswerField answer {
      id = answer_id
    , editable = False
    , hover = False
    , error = False
    , question_index = i
    , index = j } (generate_answer_feedback_field <| String.join "_" [answer_id, "feedback"])
