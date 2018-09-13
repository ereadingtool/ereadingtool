module ForgotPassword exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode

import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)


type alias ForgotPassURI = String
type alias ResetPassURI = String
type alias UserEmail = String

type alias Password = (String, String)

type alias ForgotPassResp = { errors : Dict String String, body : String }

type alias PassResetConfirmResp = { errors : Dict String String, body: String }

emptyResp : ForgotPassResp
emptyResp = { errors=Dict.fromList [], body="" }

forgotRespDecoder : Decode.Decoder (ForgotPassResp)
forgotRespDecoder =
  decode ForgotPassResp
    |> required "errors" (Decode.dict Decode.string)
    |> required "body" Decode.string