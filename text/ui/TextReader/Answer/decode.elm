module TextReader.Answer.Decode exposing (..)

import Array exposing (Array)
import Json.Decode
import Json.Decode.Pipeline exposing (required)
import TextReader.Answer.Model exposing (Answer)


answerDecoder : Json.Decode.Decoder Answer
answerDecoder =
    Json.Decode.succeed Answer
        |> required "id" Json.Decode.int
        |> required "question_id" Json.Decode.int
        |> required "text" Json.Decode.string
        |> required "order" Json.Decode.int
        |> required "feedback" Json.Decode.string


answersDecoder : Json.Decode.Decoder (Array Answer)
answersDecoder =
    Json.Decode.array answerDecoder
