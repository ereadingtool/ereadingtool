module Model exposing (Text, emptyText, TextDifficulty, TextID, Question, Answer, textsDecoder, textEncoder, textDecoder
  , textCreateRespDecoder, questionsDecoder , decodeCreateRespErrors, TextCreateRespError, textDifficultyDecoder,
    TextCreateResp)

import Date exposing (..)

import Dict exposing (Dict)

import Array exposing (Array)

import Json.Decode as Decode
import Json.Decode.Extra exposing (date)
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

import Json.Encode as Encode

type alias Text = {
    id: Maybe TextID
  , title: String
  , created_dt: Maybe Date
  , modified_dt: Maybe Date
  , source: String
  , difficulty: String
  , author: String
  , question_count : Int
  , body : String }

emptyText : Text
emptyText = {
    id = Nothing
  , title = "title"
  , created_dt = Nothing
  , modified_dt = Nothing
  , source = "source"
  , difficulty = ""
  , author = "author"
  , question_count = 0
  , body = "text" }

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
    |> required "body" Decode.string

textsDecoder : Decode.Decoder (List Text)
textsDecoder = Decode.list textDecoder

type alias TextID = Int

type alias TextCreateResp = {
    id: Maybe TextID }

type alias TextCreateRespError = Dict.Dict String String

type alias TextDifficulty = (String, String)

textDifficultyDecoder : Decode.Decoder (List TextDifficulty)
textDifficultyDecoder = Decode.keyValuePairs Decode.string

textCreateRespDecoder : Decode.Decoder (TextCreateResp)
textCreateRespDecoder =
  decode TextCreateResp
    |> optional "id" (Decode.maybe Decode.int) Nothing

textCreateRespErrDecoder : Decode.Decoder (TextCreateRespError)
textCreateRespErrDecoder = Decode.dict Decode.string

decodeCreateRespErrors : String -> Result String TextCreateRespError
decodeCreateRespErrors str = Decode.decodeString textCreateRespErrDecoder str

textEncoder : Text -> Array Question -> Encode.Value
textEncoder text questions = Encode.object [
      ("title", Encode.string text.title)
    , ("source", Encode.string text.source)
    , ("difficulty", Encode.string text.difficulty)
    , ("body", Encode.string text.body)
    , ("questions", (questionsEncoder questions))
  ]

type alias Answer = {
    id: Maybe Int
  , question_id: Maybe Int
  , text: String
  , correct: Bool
  , order: Int
  , feedback: String }


answerDecoder : Decode.Decoder Answer
answerDecoder =
  decode Answer
    |> required "id" (Decode.nullable Decode.int)
    |> required "question_id" (Decode.nullable Decode.int)
    |> required "text" Decode.string
    |> required "correct" Decode.bool
    |> required "order" Decode.int
    |> required "feedback" Decode.string

answersDecoder : Decode.Decoder (Array Answer)
answersDecoder = Decode.array answerDecoder

answersEncoder : Array Answer -> Encode.Value
answersEncoder answers =
     Encode.list
  <| Array.toList
  <| Array.map (\answer -> answerEncoder answer) answers

answerEncoder : Answer -> Encode.Value
answerEncoder answer = Encode.object [
       ("text", Encode.string answer.text)
     , ("correct", Encode.bool answer.correct)
     , ("order", Encode.int answer.order)
     , ("feedback", Encode.string answer.feedback)
  ]

type alias Question = {
    id: Maybe Int
  , text_id: Maybe Int
  , created_dt: Maybe Date
  , modified_dt: Maybe Date
  , body: String
  , order: Int
  , answers: Array Answer
  , question_type: String }

questionDecoder : Decode.Decoder Question
questionDecoder =
  decode Question
    |> required "id" (Decode.nullable Decode.int)
    |> required "text_id" (Decode.nullable Decode.int)
    |> required "created_dt" (Decode.nullable date)
    |> required "modified_dt" (Decode.nullable date)
    |> required "body" Decode.string
    |> required "order" Decode.int
    |> required "answers" answersDecoder
    |> required "question_type" Decode.string

questionsDecoder : Decode.Decoder (List Question)
questionsDecoder = Decode.list questionDecoder

questionEncoder : Question -> Encode.Value
questionEncoder question = Encode.object [
       ("body", Encode.string question.body)
     , ("order", Encode.int question.order)
     , ("answers", (answersEncoder question.answers) )
     , ("question_type", Encode.string question.question_type)
  ]

questionsEncoder : Array Question -> Encode.Value
questionsEncoder questions =
     Encode.list
  <| Array.toList
  <| Array.map (\question -> questionEncoder question) questions