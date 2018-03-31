module Model exposing (Text, Question, QuestionType, Answer, textsDecoder)

import Date exposing (..)

import Array exposing (Array)

import Json.Decode exposing (int, string, float, bool, nullable, list, array, succeed, Decoder, field, at)
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

type alias Answer = {
    id: Maybe Int
  , question_id: Maybe Int
  , text: String
  , correct: Bool
  , order: Int
  , feedback: String }


answerDecoder : Decoder Answer
answerDecoder =
  decode Answer
    |> required "id" (nullable int)
    |> required "question_id" (nullable int)
    |> required "text" string
    |> required "correct" bool
    |> required "order" int
    |> required "feedback" string

answersDecoder : Decoder (Array Answer)
answersDecoder = array answerDecoder

type alias Question = {
    id: Maybe Int
  , text_id: Maybe Int
  , created_dt: Maybe Date
  , modified_dt: Maybe Date
  , body: String
  , order: Int
  , answers: Array Answer
  , question_type: String }

questionDecoder : Decoder Question
questionDecoder =
  decode Question
    |> required "id" (nullable int)
    |> required "text_id" (nullable int)
    |> required "created_dt" (nullable date)
    |> required "modified_dt" (nullable date)
    |> required "body" string
    |> required "order" int
    |> required "answers" answersDecoder
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
