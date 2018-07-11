module Text.Decode exposing (textDecoder, textsDecoder, TextCreateResp)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)
import Json.Decode.Extra exposing (date)

import Question.Decode

import Text.Model exposing (Text)
import Field

type alias TextCreateResp = { id: Maybe Field.ID }


textDecoder : Decode.Decoder Text
textDecoder =
  decode Text
    |> required "order" Decode.int
    |> required "body" Decode.string
    |> required "question_count" Decode.int
    |> required "questions" Question.Decode.questionsDecoder

textsDecoder : Decode.Decoder (List Text)
textsDecoder = Decode.list textDecoder

