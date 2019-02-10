module Student.Profile.Decode exposing (..)

import Dict exposing (Dict)

import Json.Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

import Student.Profile exposing (StudentProfileParams, PerformanceReport)

import Student.Profile.Model

import Util exposing (stringTupleDecoder)

import Text.Translations exposing (Word, Grammemes)

import Text.Translations.Decode


username_valid_decoder : Json.Decode.Decoder Student.Profile.Model.UsernameUpdate
username_valid_decoder =
  decode Student.Profile.Model.UsernameUpdate
    |> required "username" Json.Decode.string
    |> required "valid" (Json.Decode.nullable Json.Decode.bool)
    |> required "msg" (Json.Decode.nullable Json.Decode.string)


wordTextWordDecoder : Json.Decode.Decoder (Word, Text.Translations.Decode.TextWord)
wordTextWordDecoder =
  Json.Decode.map2 (,)
    (Json.Decode.index 0 Json.Decode.string)
    (Json.Decode.index 1 Text.Translations.Decode.textWordDecoder)

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
    |> required "performance_report" performanceReportDecoder
    |> required "flashcards" (Json.Decode.nullable (Json.Decode.list wordTextWordDecoder))

studentProfileDecoder : Json.Decode.Decoder Student.Profile.StudentProfile
studentProfileDecoder =
  Json.Decode.map Student.Profile.init_profile studentProfileParamsDecoder