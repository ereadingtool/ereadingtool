module TextReader.Answer.Decode exposing (..)

import Answer.Decode
import Array exposing (Array)
import Json.Decode
import Json.Decode.Extra exposing (date)
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required, resolve)
import TextReader.Answer.Model exposing (Answer)
import TextReader.Model exposing (..)
import TextReader.Question.Decode
import TextReader.Question.Model exposing (Question, TextQuestion)
import TextReader.Section.Decode


answerDecoder : Json.Decode.Decoder Answer
answerDecoder =
    decode Answer
        |> required "id" Json.Decode.int
        |> required "question_id" Json.Decode.int
        |> required "text" Json.Decode.string
        |> required "order" Json.Decode.int
        |> required "feedback" Json.Decode.string


answersDecoder : Json.Decode.Decoder (Array Answer)
answersDecoder =
    Json.Decode.array answerDecoder
