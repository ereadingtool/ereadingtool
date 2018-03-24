module Model exposing (Text, Texts, Model, textsDecoder)

import Html exposing (..)

import Html.Attributes exposing (classList, attribute)
import Html.Events exposing (..)

import Http exposing (..)

import Array exposing (..)

import Date exposing (..)

import Markdown

import Time exposing (Time, second)

import Json.Decode exposing (int, string, float, list, succeed, Decoder)
import Json.Decode.Extra exposing (date)
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)


type alias Text = {
    id: Int
  , title: String
  , created_dt: Date
  , modified_dt: Date
  , source: String
  , difficulty: String
  , question_count : Int
  , body : String }


type alias Texts = List Text

type alias Model = { texts : List Text }


textDecoder : Decoder Text
textDecoder =
  decode Text
    |> required "id" int
    |> required "title" string
    |> required "created_dt" date
    |> required "modified_dt" date
    |> required "source" string
    |> required "difficulty" string
    |> required "question_count" int
    |> required "body" string

textsDecoder : Decoder (List Text)
textsDecoder = list textDecoder
