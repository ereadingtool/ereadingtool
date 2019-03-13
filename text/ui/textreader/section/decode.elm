module TextReader.Section.Decode exposing (..)

import Dict exposing (Dict)
import Array exposing (Array)

import Json.Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

import Text.Translations exposing (..)

import Text.Translations.Decode

import TextReader.TextWord
import TextReader.Section.Model exposing (TextSection, Section, Words)

import TextReader.Question.Decode


sectionDecoder : Json.Decode.Decoder Section
sectionDecoder =
  Json.Decode.map TextReader.Section.Model.newSection textSectionDecoder

textWordTranslationDecoder : Json.Decode.Decoder TextReader.TextWord.Translation
textWordTranslationDecoder =
  decode TextReader.TextWord.Translation
    |> required "correct_for_context" Json.Decode.bool
    |> required "text" Json.Decode.string

textWordTranslationsDecoder : Json.Decode.Decoder (Maybe (List TextReader.TextWord.Translation))
textWordTranslationsDecoder =
  Json.Decode.nullable (Json.Decode.list textWordTranslationDecoder)

textWordInstanceDecoder : Json.Decode.Decoder TextReader.TextWord.TextWord
textWordInstanceDecoder =
  Json.Decode.map6 TextReader.TextWord.new
    (Json.Decode.field "id" Json.Decode.int)
    (Json.Decode.field "instance" Json.Decode.int)
    (Json.Decode.field "phrase" Json.Decode.string)
    (Json.Decode.field "grammemes"
      (Json.Decode.nullable (Json.Decode.map Dict.fromList Text.Translations.Decode.grammemesDecoder)))

    (Json.Decode.field "translations" textWordTranslationsDecoder)

    Text.Translations.Decode.wordDecoder

textWordDictInstancesDecoder : Json.Decode.Decoder (Dict Phrase (Array TextReader.TextWord.TextWord))
textWordDictInstancesDecoder =
  Json.Decode.dict (Json.Decode.array textWordInstanceDecoder)

textSectionDecoder : Json.Decode.Decoder TextSection
textSectionDecoder =
  decode TextSection
    |> required "order" Json.Decode.int
    |> required "body" Json.Decode.string
    |> required "question_count" Json.Decode.int
    |> required "questions" TextReader.Question.Decode.questionsDecoder
    |> required "num_of_sections" Json.Decode.int
    |> required "translations" textWordDictInstancesDecoder

textSectionsDecoder : Json.Decode.Decoder (List TextSection)
textSectionsDecoder = Json.Decode.list textSectionDecoder
