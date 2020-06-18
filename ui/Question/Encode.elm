module Question.Encode exposing (questionEncoder, questionsEncoder)

import Answer.Encode
import Array exposing (Array)
import Json.Encode as Encode
import Question.Model exposing (Question)


questionEncoder : Question -> Encode.Value
questionEncoder question =
    Encode.object
        [ ( "body", Encode.string question.body )
        , ( "order", Encode.int question.order )
        , ( "answers", Answer.Encode.answersEncoder question.answers )
        , ( "question_type", Encode.string question.question_type )
        ]


questionsEncoder : Array Question -> Encode.Value
questionsEncoder questions =
    Encode.list <|
        Array.toList <|
            Array.map (\question -> questionEncoder question) questions
