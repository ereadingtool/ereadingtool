module ForgotPassword exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required, resolve)


type URI
    = URI String


type ForgotPassURI
    = ForgotPassURI URI


type ResetPassURI
    = ResetPassURI URI


type UserEmail
    = UserEmail String


type Password1
    = Password1 String


type Password2
    = Password2 String


type UIdb64
    = UIdb64 String


type Password
    = Password Password1 Password2 UIdb64


type alias ForgotPassResp =
    { errors : Dict String String, body : String }


type alias PassResetConfirmResp =
    { errors : Dict String String, body : String, redirect : String }


userEmailisEmpty : UserEmail -> Bool
userEmailisEmpty (UserEmail email) =
    String.isEmpty email


userEmailtoString : UserEmail -> String
userEmailtoString (UserEmail email) =
    email


forgotPassURI : ForgotPassURI -> URI
forgotPassURI (ForgotPassURI uri) =
    uri


resetPassURI : ResetPassURI -> URI
resetPassURI (ResetPassURI uri) =
    uri


uriToString : URI -> String
uriToString (URI uri) =
    uri


password1 : Password -> Password1
password1 (Password pw1 _ _) =
    pw1


password2 : Password -> Password2
password2 (Password _ pw2 _) =
    pw2


password1toString : Password1 -> String
password1toString (Password1 pw) =
    pw


password2toString : Password2 -> String
password2toString (Password2 pw) =
    pw


uidb64 : Password -> UIdb64
uidb64 (Password _ _ uidb64) =
    uidb64


uidb64toString : UIdb64 -> String
uidb64toString (UIdb64 uidb64) =
    uidb64


emptyPassResetResp : PassResetConfirmResp
emptyPassResetResp =
    { errors = Dict.fromList [], body = "", redirect = "" }


emptyForgotPassResp : ForgotPassResp
emptyForgotPassResp =
    { errors = Dict.fromList [], body = "" }


forgotPassRespDecoder : Decode.Decoder ForgotPassResp
forgotPassRespDecoder =
    decode ForgotPassResp
        |> required "errors" (Decode.dict Decode.string)
        |> required "body" Decode.string


forgotPassConfirmRespDecoder : Decode.Decoder PassResetConfirmResp
forgotPassConfirmRespDecoder =
    decode PassResetConfirmResp
        |> required "errors" (Decode.dict Decode.string)
        |> required "body" Decode.string
        |> required "redirect" Decode.string
