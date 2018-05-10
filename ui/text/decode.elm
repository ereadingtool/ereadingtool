module Text.Decode exposing (textDecoder, textsDecoder, textCreateRespDecoder, decodeCreateRespErrors
  , textCreateRespErrDecoder, TextCreateRespError, TextCreateResp)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)
import Json.Decode.Extra exposing (date)

import Question.Decode

import Dict exposing (Dict)

import Text.Model exposing (Text)
import Field

type alias TextCreateResp = { id: Maybe Field.ID }

type alias TextCreateRespError = Dict String String

textDecoder : Decode.Decoder Text
textDecoder =
  decode Text
    |> required "id" (Decode.nullable Decode.int)
    |> required "title" Decode.string
    |> required "created_dt" (Decode.nullable date)
    |> required "modified_dt" (Decode.nullable date)
    |> required "source" Decode.string
    |> required "difficulty" Decode.string
    |> required "author" Decode.string
    |> required "question_count" Decode.int
    |> required "questions" Question.Decode.questionsDecoder
    |> required "body" Decode.string

textsDecoder : Decode.Decoder (List Text)
textsDecoder = Decode.list textDecoder

textCreateRespDecoder : Decode.Decoder (TextCreateResp)
textCreateRespDecoder =
  decode TextCreateResp
    |> optional "id" (Decode.maybe Field.fieldIDDecoder) Nothing

textCreateRespErrDecoder : Decode.Decoder (TextCreateRespError)
textCreateRespErrDecoder = Decode.dict Decode.string

decodeCreateRespErrors : String -> Result String TextCreateRespError
decodeCreateRespErrors str = Decode.decodeString textCreateRespErrDecoder str
