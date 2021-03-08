module Answer.Encode exposing (answerEncoder, answersEncoder)

import Answer.Model exposing (Answer)
import Array exposing (Array)
import Json.Encode as Encode


answersEncoder : Array Answer -> Encode.Value
answersEncoder answers =
    Encode.list answerEncoder <|
        Array.toList answers


answerEncoder : Answer -> Encode.Value
answerEncoder answer =
    Encode.object
        [ ( "text", Encode.string answer.text )
        , ( "correct", Encode.bool answer.correct )
        , ( "order", Encode.int answer.order )
        , ( "feedback", Encode.string answer.feedback )
        ]
