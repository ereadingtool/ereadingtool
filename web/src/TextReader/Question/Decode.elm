module TextReader.Question.Decode exposing (..)

import Array exposing (Array)
import DateTime
import Json.Decode
import Json.Decode.Extra exposing (posix)
import Json.Decode.Pipeline exposing (required)
import TextReader.Answer.Model exposing (Answer)
import TextReader.Question.Model exposing (Question, TextQuestion)


answerDecoder : Json.Decode.Decoder Answer
answerDecoder =
    Json.Decode.succeed Answer
        |> required "id" Json.Decode.int
        |> required "question_id" Json.Decode.int
        |> required "text" Json.Decode.string
        |> required "order" Json.Decode.int
        |> required "answered_correctly" (Json.Decode.nullable Json.Decode.bool)
        |> required "feedback" Json.Decode.string


answersDecoder : Json.Decode.Decoder (Array Answer)
answersDecoder =
    Json.Decode.array answerDecoder


questionDecoder : Json.Decode.Decoder Question
questionDecoder =
    Json.Decode.succeed Question
        |> required "id" Json.Decode.int
        |> required "text_section_id" Json.Decode.int
        |> required "created_dt" (Json.Decode.nullable (Json.Decode.map DateTime.fromPosix posix))
        |> required "modified_dt" (Json.Decode.nullable (Json.Decode.map DateTime.fromPosix posix))
        |> required "body" Json.Decode.string
        |> required "order" Json.Decode.int
        |> required "answers" answersDecoder
        |> required "question_type" Json.Decode.string


questionsDecoder : Json.Decode.Decoder (Array Question)
questionsDecoder =
    Json.Decode.array questionDecoder
