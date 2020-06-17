module TextReader.Answer.Decode exposing (..)

import Array exposing (Array)

import Json.Decode
import TextReader.Model exposing (..)

import Answer.Decode

import TextReader.Answer.Model exposing (Answer)

import TextReader.Question.Decode
import TextReader.Question.Model exposing (TextQuestion, Question)

import TextReader.Section.Decode

import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)
import Json.Decode.Extra exposing (date)


answerDecoder : Json.Decode.Decoder Answer
answerDecoder =
  decode Answer
    |> required "id" (Json.Decode.int)
    |> required "question_id" (Json.Decode.int)
    |> required "text" Json.Decode.string
    |> required "order" Json.Decode.int
    |> required "feedback" Json.Decode.string

answersDecoder : Json.Decode.Decoder (Array Answer)
answersDecoder = Json.Decode.array answerDecoder
