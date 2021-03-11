module TextReader.Question.Model exposing
    ( Question
    , TextQuestion
    , answered
    , answered_correctly
    , answers
    , initTextQuestion
    , question
    )

import Array exposing (Array)
import TextReader.Answer.Model exposing (Answer, TextAnswer)
import Time exposing (Posix)


type alias Question =
    { id : Int
    , text_section_id : Int
    , created_dt : Maybe Posix
    , modified_dt : Maybe Posix
    , body : String
    , order : Int
    , answers : Array Answer
    , question_type : String
    }


type alias AnsweredCorrectly =
    Maybe Bool


type TextQuestion
    = TextQuestion Question AnsweredCorrectly (Array TextAnswer)


initTextQuestion : Question -> TextQuestion
initTextQuestion q =
    TextQuestion q
        Nothing
        (Array.map TextReader.Answer.Model.initTextAnswer q.answers)


answered : TextQuestion -> Bool
answered text_question =
    case answered_correctly text_question of
        Just correct ->
            correct

        Nothing ->
            False


question : TextQuestion -> Question
question (TextQuestion q _ _) =
    q


answers : TextQuestion -> Array TextAnswer
answers (TextQuestion _ _ ans) =
    ans


answered_correctly : TextQuestion -> Maybe Bool
answered_correctly (TextQuestion _ is_answered_correctly _) =
    is_answered_correctly
