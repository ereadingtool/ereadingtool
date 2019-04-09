module Student.Profile.Decode exposing (..)

import Json.Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

import Student.Profile exposing (StudentProfileParams)

import Student.Performance.Report exposing (PerformanceReport)

import Student.Profile.Model

import Util exposing (stringTupleDecoder)

import Text.Translations exposing (Phrase, Grammemes)
import Text.Translations.Decode

import TextReader.Section.Decode
import TextReader.TextWord


username_valid_decoder : Json.Decode.Decoder Student.Profile.Model.UsernameUpdate
username_valid_decoder =
  decode Student.Profile.Model.UsernameUpdate
    |> required "username" Json.Decode.string
    |> required "valid" (Json.Decode.nullable Json.Decode.bool)
    |> required "msg" (Json.Decode.nullable Json.Decode.string)

textWordParamsDecoder : Json.Decode.Decoder TextReader.TextWord.TextWordParams
textWordParamsDecoder =
  decode TextReader.TextWord.TextWordParams
    |> required "id" Json.Decode.int
    |> required "instance" Json.Decode.int
    |> required "phrase" Json.Decode.string
    |> required "grammemes" (Json.Decode.nullable (Json.Decode.list stringTupleDecoder))
    |> required "translations" TextReader.Section.Decode.textWordTranslationsDecoder
    |> required "word"
         (Json.Decode.map2 (,)
           (Json.Decode.index 0 Json.Decode.string)
           (Json.Decode.index 1 (Json.Decode.nullable Text.Translations.Decode.textGroupDetailsDecoder)))

wordTextWordDecoder : Json.Decode.Decoder (Maybe (List (Phrase, TextReader.TextWord.TextWordParams)))
wordTextWordDecoder =
  Json.Decode.nullable
    (Json.Decode.list
    (Json.Decode.map2 (,)
      (Json.Decode.index 0 Json.Decode.string)
      (Json.Decode.index 1 textWordParamsDecoder)))

performanceReportDecoder : Json.Decode.Decoder PerformanceReport
performanceReportDecoder =
  decode PerformanceReport
    |> required "html" Json.Decode.string
    |> required "pdf_link" Json.Decode.string

studentProfileParamsDecoder : Json.Decode.Decoder StudentProfileParams
studentProfileParamsDecoder =
  decode StudentProfileParams
    |> required "id" (Json.Decode.nullable Json.Decode.int)
    |> required "username" Json.Decode.string
    |> required "email" Json.Decode.string
    |> required "difficulty_preference" (Json.Decode.nullable stringTupleDecoder)
    |> required "difficulties" (Json.Decode.list stringTupleDecoder)

studentProfileDecoder : Json.Decode.Decoder Student.Profile.StudentProfile
studentProfileDecoder =
  Json.Decode.map
    Student.Profile.initProfile
      (Json.Decode.field "profile" studentProfileParamsDecoder)