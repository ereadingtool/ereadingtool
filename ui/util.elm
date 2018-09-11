module Util exposing (..)

import Regex

import Json.Decode

import Html
import Json.Decode

import Html.Events


valid_email_regex : Regex.Regex
valid_email_regex = Regex.regex "^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+.[a-zA-Z0-9-.]+$" |> Regex.caseInsensitive

is_valid_email : String -> Bool
is_valid_email addr = Regex.contains valid_email_regex addr

tupleDecoder : Json.Decode.Decoder ( String, String )
tupleDecoder = Json.Decode.map2 (,) (Json.Decode.index 0 Json.Decode.string) (Json.Decode.index 1 Json.Decode.string)

onEnterUp : msg -> Html.Attribute msg
onEnterUp msg =
  Html.Events.on "keyup"
    (Html.Events.keyCode
  |> Json.Decode.andThen (\key ->
       case key of
         13 ->
           Json.Decode.succeed msg
         _ ->
           Json.Decode.fail "not enter key" ))
