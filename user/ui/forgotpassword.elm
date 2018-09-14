module ForgotPassword exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode

import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)


type alias ForgotPassURI = String
type alias ResetPassURI = String
type alias UserEmail = String

type alias Password = {password: String, confirm_password: String, uidb64 : String }

type alias ForgotPassResp = { errors : Dict String String, body : String }

type alias PassResetConfirmResp = { errors : Dict String String, body: String }

emptyPassResetResp : PassResetConfirmResp
emptyPassResetResp = {errors=Dict.fromList [], body=""}

emptyForgotPassResp : ForgotPassResp
emptyForgotPassResp = { errors=Dict.fromList [], body="" }

forgotRespDecoder : Decode.Decoder (ForgotPassResp)
forgotRespDecoder =
  decode ForgotPassResp
    |> required "errors" (Decode.dict Decode.string)
    |> required "body" Decode.string