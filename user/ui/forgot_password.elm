module ForgotPassword exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode

import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)


type alias ForgotPassURI = String
type alias UserEmail = String

type alias ForgotPassResp = { errors : Dict String String, body : String }


forgotRespDecoder : Decode.Decoder (ForgotPassResp)
forgotRespDecoder =
  decode ForgotPassURI
    |> required "id" Decode.int
    |> required "redirect" Decode.string