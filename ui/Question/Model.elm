module Question.Model exposing (Question, new_question, initial_questions)

import Array exposing (Array)
import Date exposing (Date)

import Answer.Model

type alias Question = {
    id: Maybe Int
  , text_id: Maybe Int
  , created_dt: Maybe Date
  , modified_dt: Maybe Date
  , body: String
  , order: Int
  , answers: Array Answer.Model.Answer
  , question_type: String }

new_question : Int -> Question
new_question i = {
    id = Nothing
  , text_id = Nothing
  , created_dt = Nothing
  , modified_dt = Nothing
  , body = ""
  , order = i
  , answers = Answer.Model.generate_answers 4
  , question_type = "main_idea" }

initial_questions : Array Question
initial_questions = Array.fromList [(new_question 0)]
