module Question.Model exposing (Question, initial_questions, new_question)

import Answer.Model
import Array exposing (Array)
import DateTime exposing (DateTime)


type alias Question =
    { id : Maybe Int
    , text_id : Maybe Int
    , created_dt : Maybe DateTime
    , modified_dt : Maybe DateTime
    , body : String
    , order : Int
    , answers : Array Answer.Model.Answer
    , question_type : String
    }


new_question : Int -> Question
new_question i =
    { id = Nothing
    , text_id = Nothing
    , created_dt = Nothing
    , modified_dt = Nothing
    , body = ""
    , order = i
    , answers = Answer.Model.generate_answers 4
    , question_type = "main_idea"
    }


initial_questions : Array Question
initial_questions =
    Array.fromList [ new_question 0 ]
