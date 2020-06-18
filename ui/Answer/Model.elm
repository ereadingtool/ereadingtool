module Answer.Model exposing (Answer, default_answer_text, generate_answer, generate_answers)

import Array exposing (Array)


type alias Answer =
    { id : Maybe Int
    , question_id : Maybe Int
    , text : String
    , correct : Bool
    , order : Int
    , feedback : String
    }


default_answer_text : Answer -> String
default_answer_text answer =
    String.join " " [ "Click to write choice", toString (answer.order + 1) ]


generate_answer : Int -> Answer
generate_answer i =
    { id = Nothing
    , question_id = Nothing
    , text = ""
    , correct = False
    , order = i
    , feedback = ""
    }


generate_answers : Int -> Array Answer
generate_answers n =
    Array.fromList <|
        List.map generate_answer <|
            List.range 0 (n - 1)
