module TextReader.Question.Model exposing (..)

import Array exposing (Array)
import Date exposing (Date)
import TextReader.Answer.Model exposing (Answer, TextAnswer)


type alias Question =
    { id : Int
    , text_section_id : Int
    , created_dt : Maybe Date
    , modified_dt : Maybe Date
    , body : String
    , order : Int
    , answers : Array Answer
    , question_type : String
    }


type alias AnsweredCorrectly =
    Maybe Bool


type TextQuestion
    = TextQuestion Question AnsweredCorrectly (Array TextAnswer)


gen_text_question : Question -> TextQuestion
gen_text_question question =
    TextQuestion question
        Nothing
        (Array.map TextReader.Answer.Model.gen_text_answer question.answers)


answered : TextQuestion -> Bool
answered text_question =
    case answered_correctly text_question of
        Just correct ->
            correct

        Nothing ->
            False


question : TextQuestion -> Question
question (TextQuestion question _ _) =
    question


answers : TextQuestion -> Array TextAnswer
answers (TextQuestion _ _ answers) =
    answers


answered_correctly : TextQuestion -> Maybe Bool
answered_correctly (TextQuestion _ answered_correctly _) =
    answered_correctly
