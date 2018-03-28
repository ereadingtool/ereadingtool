module Model exposing (Text, Question, textsDecoder)

import Date exposing (..)

import Json.Decode exposing (int, string, float, nullable, list, succeed, Decoder, field, at)
import Json.Decode.Extra exposing (date)
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)


type alias Text = {
    id: Maybe Int
  , title: String
  , created_dt: Maybe Date
  , modified_dt: Maybe Date
  , source: String
  , difficulty: String
  , question_count : Int
  , body : String }


type QuestionType = MainIdea | Detail

type alias Question = {
    id: Maybe Int
  , text: String
  , order: Int
  , body: String
  , question_type: String }


questionDecoder : Decoder Question
questionDecoder =
  decode Question
    |> required "id" (nullable int)
    |> required "text" string
    |> required "order" int
    |> required "body" string
    |> required "question_type" string


questionsDecoder : Decoder (List Question)
questionsDecoder = list questionDecoder

textDecoder : Decoder Text
textDecoder =
  decode Text
    |> required "id" (nullable int)
    |> required "title" string
    |> required "created_dt" (nullable date)
    |> required "modified_dt" (nullable date)
    |> required "source" string
    |> required "difficulty" string
    |> required "question_count" int
    |> required "body" string

textsDecoder : Decoder (List Text)
textsDecoder = list textDecoder
