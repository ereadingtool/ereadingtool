module Text.Definitions exposing (..)

import Json.Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

import Dict exposing (Dict)

type alias Word = String
type alias Meaning = String

type alias Grammemes = {pos: String, tense: String, aspect: String, form: String, mood: String}

type alias TextWord = {word: Word, grammemes: Grammemes, meaning: Maybe Meaning}

type alias Flashcards = Dict Word TextWord

grammemesDecoder : Json.Decode.Decoder Grammemes
grammemesDecoder =
  decode Grammemes
    |> required "pos" Json.Decode.string
    |> required "tense" Json.Decode.string
    |> required "aspect" Json.Decode.string
    |> required "form" Json.Decode.string
    |> required "mood" Json.Decode.string

textWordDecoder : Json.Decode.Decoder TextWord
textWordDecoder =
  decode TextWord
    |> required "word" Json.Decode.string
    |> required "grammemes" grammemesDecoder
    |> required "meaning" (Json.Decode.nullable Json.Decode.string)


