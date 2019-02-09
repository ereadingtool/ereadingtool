module Text.Translations exposing (..)

import Json.Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

import Dict exposing (Dict)

type alias Id = String
type alias Instance = Int
type alias Phrase = String
type alias Word = String
type alias Token = String
type alias Meaning = String

type alias Grammemes = {
    pos: Maybe String
  , tense: Maybe String
  , aspect: Maybe String
  , form: Maybe String
  , mood: Maybe String }

type alias TextWord = {word: Word, grammemes: Grammemes, translation: Maybe String}

type alias Flashcards = Dict Word TextWord

grammemesDecoder : Json.Decode.Decoder Grammemes
grammemesDecoder =
  decode Grammemes
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


