module TextReader.Section.Decode exposing (..)

import Json.Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

import Text.Decode

import TextReader.Section.Model exposing (TextSection, Section)

import TextReader.Question.Decode


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
    |> required "num_of_sections" Json.Decode.int
    |> required "translations" Text.Decode.wordsDecoder

textSectionsDecoder : Json.Decode.Decoder (List TextSection)
textSectionsDecoder = Json.Decode.list textSectionDecoder
