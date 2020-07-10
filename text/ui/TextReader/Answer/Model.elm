module TextReader.Answer.Model exposing (..)


type alias AnswerCorrect =
    Bool


type alias Answer =
    { id : Int
    , question_id : Int
    , text : String
    , order : Int
    , answered_correctly : Maybe Bool
    , feedback : String
    }


type TextAnswer
    = TextAnswer Answer


initTextAnswer : Answer -> TextAnswer
initTextAnswer ans =
    TextAnswer ans


correct : TextAnswer -> Bool
correct text_answer =
    case (answer text_answer).answered_correctly of
        Just is_correct ->
            is_correct

        Nothing ->
            False


answered : TextAnswer -> Bool
answered text_answer =
    case (answer text_answer).answered_correctly of
        Just _ ->
            True

        Nothing ->
            False


feedback_viewable : TextAnswer -> Bool
feedback_viewable text_answer =
    answered text_answer


selected : TextAnswer -> Bool
selected text_answer =
    answered text_answer


answer : TextAnswer -> Answer
answer (TextAnswer ans) =
    ans
