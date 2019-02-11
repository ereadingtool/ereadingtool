module Text.Translations.Decode exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)

import Text.Translations exposing (..)

import Text.Translations.TextWord

import Json.Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)


type alias TextWord = {word: Word, grammemes: Grammemes, translation: Maybe String}

type alias Flashcards = Dict Word TextWord
type alias TextWords = Dict Word TextWord

type alias TextWordTranslationDeleteResp = {
    word: String
  , instance: Int
  , translation: Translation
  , deleted: Bool }

type alias TextWordMergeResp = {
    text_words: List TextWord
  , grouped : Bool
  , error: Maybe String }


wordValuesDecoder : Json.Decode.Decoder WordValues
wordValuesDecoder =
  decode WordValues
    |> required "grammemes" grammemesDecoder
    |> required "translations" (Json.Decode.nullable (Json.Decode.list Json.Decode.string))

wordsDecoder : Json.Decode.Decoder Words
wordsDecoder =
  Json.Decode.dict wordValuesDecoder

textWordMergeDecoder : Json.Decode.Decoder TextWordMergeResp
textWordMergeDecoder =
  decode TextWordMergeResp
    |> required "text_words" textWordsDecoder
    |> required "grouped" Json.Decode.bool
    |> required "error" (Json.Decode.nullable Json.Decode.string)

textTranslationUpdateRespDecoder : Json.Decode.Decoder (Word, Int, Translation)
textTranslationUpdateRespDecoder =
  Json.Decode.map3 (,,)
    (Json.Decode.field "word" Json.Decode.string)
    (Json.Decode.field "instance" Json.Decode.int)
    (Json.Decode.field "translation" textWordTranslationsDecoder)

textTranslationAddRespDecoder : Json.Decode.Decoder (Word, Int, Translation)
textTranslationAddRespDecoder =
  Json.Decode.map3 (,,)
    (Json.Decode.field "word" Json.Decode.string)
    (Json.Decode.field "instance" Json.Decode.int)
    (Json.Decode.field "translation" textWordTranslationsDecoder)

textTranslationRemoveRespDecoder : Json.Decode.Decoder TextWordTranslationDeleteResp
textTranslationRemoveRespDecoder =
  decode TextWordTranslationDeleteResp
    |> required "word" Json.Decode.string
    |> required "instance" Json.Decode.int
    |> required "translation" textWordTranslationsDecoder
    |> required "deleted" Json.Decode.bool

textWordDictInstancesDecoder : Json.Decode.Decoder (Dict Word (Array Text.Translations.TextWord.TextWord))
textWordDictInstancesDecoder =
  Json.Decode.dict (Json.Decode.array textWordInstanceDecoder)

textWordInstancesDecoder : Json.Decode.Decoder (List Text.Translations.TextWord.TextWord)
textWordInstancesDecoder =
  Json.Decode.list textWordInstanceDecoder

textWordTranslationsDecoder : Json.Decode.Decoder Translation
textWordTranslationsDecoder =
  decode Translation
    |> required "id" Json.Decode.int
    |> required "correct_for_context" Json.Decode.bool
    |> required "text" Json.Decode.string

textWordsDecoder : Json.Decode.Decoder (List TextWord)
textWordsDecoder =
  Json.Decode.list textWordDecoder

textGroupDetailsDecoder : Json.Decode.Decoder TextGroupDetails
textGroupDetailsDecoder =
  decode TextGroupDetails
    |> required "id" Json.Decode.int
    |> required "instance" Json.Decode.int
    |> required "pos" Json.Decode.int
    |> required "length" Json.Decode.int

wordDecoder : Json.Decode.Decoder Text.Translations.TextWord.Word
wordDecoder =
  Json.Decode.field "word_type" (Json.Decode.string)
    |> Json.Decode.andThen wordHelpDecoder

wordHelpDecoder : String -> Json.Decode.Decoder Text.Translations.TextWord.Word
wordHelpDecoder word_type =
  case word_type of
    "single" ->
      Json.Decode.map Text.Translations.TextWord.Word (Json.Decode.nullable textGroupDetailsDecoder)

    "compound" ->
      Json.Decode.succeed Text.Translations.TextWord.CompoundWord

    _ ->
      Json.Decode.fail "Unsupported word type"

textWordInstanceDecoder : Json.Decode.Decoder Text.Translations.TextWord.TextWord
textWordInstanceDecoder =
  Json.Decode.map6 Text.Translations.TextWord.new
    Json.Decode.int
    Json.Decode.int
    Json.Decode.string
    grammemesDecoder
    (Json.Decode.nullable (Json.Decode.list textWordTranslationsDecoder))
    wordDecoder

grammemesDecoder : Json.Decode.Decoder Text.Translations.Grammemes
grammemesDecoder =
  decode Text.Translations.Grammemes
    |> required "pos" (Json.Decode.nullable Json.Decode.string)
    |> required "tense" (Json.Decode.nullable Json.Decode.string)
    |> required "aspect" (Json.Decode.nullable Json.Decode.string)
    |> required "form" (Json.Decode.nullable Json.Decode.string)
    |> required "mood" (Json.Decode.nullable Json.Decode.string)

textWordDecoder : Json.Decode.Decoder TextWord
textWordDecoder =
  decode TextWord
    |> required "word" Json.Decode.string
    |> required "grammemes" grammemesDecoder
    |> required "translation" (Json.Decode.nullable Json.Decode.string)


