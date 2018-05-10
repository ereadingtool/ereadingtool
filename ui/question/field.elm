module Question.Field exposing (QuestionField, generate_question_field, update_question_field, add_new_question
  , delete_question, initial_question_fields)

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

question_index : QuestionField -> Int
question_index (QuestionField _ attr _) = attr.index

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