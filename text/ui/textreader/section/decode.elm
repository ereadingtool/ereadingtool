module TextReader.Section.Decode exposing (..)


import Array exposing (Array)

import Json.Decode
import TextReader.Model exposing (..)

import Answer.Decode

import TextReader.Answer.Model exposing (Answer)

import TextReader.Question.Decode
import TextReader.Question.Model exposing (TextQuestion, Question)

import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)
import Json.Decode.Extra exposing (date)

import TextReader.Section.Model exposing (TextSection, Section)


sectionDecoder : Json.Decode.Decoder Section
sectionDecoder =
  Json.Decode.map TextReader.Section.Model.newSection textSectionDecoder

textSectionDecoder : Json.Decode.Decoder TextSection
textSectionDecoder =
  decode TextSection
    |> required "order" Json.Decode.int
    |> required "body" Json.Decode.string
    |> required "question_count" Json.Decode.int
    |> required "questions" TextReader.Question.Decode.questionsDecoder

textSectionsDecoder : Json.Decode.Decoder (List TextSection)
textSectionsDecoder = Json.Decode.list textSectionDecoder
