import Html exposing (Html, div)
import Flags

import SignUp
import Navigation
import Dict exposing (Dict)
import Json.Encode as Encode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)
import Json.Decode as Decode

import HttpHelpers exposing (post_with_headers)
import Config exposing (instructor_signup_api_endpoint)
import Http exposing (..)

type alias SignUpResp = { id: SignUp.UserID, redirect: SignUp.URI }

type alias SignUpParams = {
    email : String
  , password : String
  , confirm_password : String }

type Msg =
    ToggleShowPassword
  | UpdateEmail String
  | UpdatePassword String
  | UpdateConfirmPassword String
  | Submitted (Result Http.Error SignUpResp)
  | Submit

type alias Model = {
    flags : Flags.UnAuthedFlags
  , signup_params : SignUpParams
  , show_passwords : Bool
  , errors : Dict String String }


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

signUpEncoder : SignUpParams -> Encode.Value
signUpEncoder signup_params = Encode.object [
     ("email", Encode.string signup_params.email)
   , ("password", Encode.string signup_params.password)
   , ("confirm_password", Encode.string signup_params.confirm_password)
  ]

signUpRespDecoder : Decode.Decoder (SignUpResp)
signUpRespDecoder =
  decode SignUpResp
    |> required "id" Decode.int
    |> required "redirect" Decode.string

post_signup : Flags.CSRFToken -> SignUpParams -> Cmd Msg
post_signup csrftoken signup_params =
  let encoded_signup_params = signUpEncoder signup_params
      req =
    post_with_headers
       instructor_signup_api_endpoint
       [Http.header "X-CSRFToken" csrftoken]
       (Http.jsonBody encoded_signup_params)
       signUpRespDecoder
  in
    Http.send Submitted req

init : Flags.UnAuthedFlags -> (Model, Cmd Msg)
init flags = ({
    flags = flags
  , signup_params = {
      email=""
    , password=""
    , confirm_password=""
  }
  , show_passwords = False
  , errors = Dict.fromList [] }, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  ToggleShowPassword -> (SignUp.toggle_show_password model, Cmd.none)
  UpdatePassword password -> (SignUp.update_password model password, Cmd.none)
  UpdateConfirmPassword confirm_password -> (SignUp.update_confirm_password model confirm_password, Cmd.none)
  UpdateEmail addr -> (SignUp.update_email model addr, Cmd.none)

  Submit -> (SignUp.submit model, post_signup model.flags.csrftoken model.signup_params)
  Submitted (Ok resp) -> (model, Navigation.load resp.redirect)
  Submitted (Err err) -> case err of
      Http.BadStatus resp -> case (Decode.decodeString (Decode.dict Decode.string) resp.body) of
        Ok errors -> ({ model | errors = errors }, Cmd.none)
        _ -> (model, Cmd.none)
      Http.BadPayload err resp -> (model, Cmd.none)
      _ -> (model, Cmd.none)

main : Program Flags.UnAuthedFlags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = (SignUp.view UpdateEmail (ToggleShowPassword, UpdatePassword, UpdateConfirmPassword) Submit)
    , subscriptions = subscriptions
    , update = update
    }
