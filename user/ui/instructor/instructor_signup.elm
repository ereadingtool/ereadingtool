import User

import Html exposing (Html, div)
import Html.Attributes exposing (classList, class, attribute)
import Html.Events exposing (onInput)

import Flags
import User.Flags.UnAuthed exposing (UnAuthedUserFlags)

import SignUp
import Navigation
import Dict exposing (Dict)
import Json.Encode as Encode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)
import Json.Decode as Decode

import HttpHelpers exposing (post_with_headers)

import Http exposing (..)

import Views

import Menu.Msg as MenuMsg

type alias SignUpResp = { id: SignUp.UserID, redirect: SignUp.URI }

type alias InviteCode = String

type alias SignUpParams = {
    email : String
  , password : String
  , confirm_password : String
  , invite_code : InviteCode }

type Msg =
    ToggleShowPassword
  | UpdateEmail String
  | UpdatePassword String
  | UpdateConfirmPassword String
  | UpdateInviteCode String
  | Submitted (Result Http.Error SignUpResp)
  | Submit
  | Logout MenuMsg.Msg


type alias Model = {
    flags : UnAuthedUserFlags
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
   , ("invite_code", Encode.string signup_params.invite_code)
  ]

signUpRespDecoder : Decode.Decoder (SignUpResp)
signUpRespDecoder =
  decode SignUpResp
    |> required "id" Decode.int
    |> required "redirect" Decode.string

post_signup : Flags.CSRFToken -> User.SignUpURI -> SignUpParams -> Cmd Msg
post_signup csrftoken instructor_signup_api_endpoint signup_params =
  let
    encoded_signup_params = signUpEncoder signup_params
    req =
      post_with_headers
       instructor_signup_api_endpoint
       [Http.header "X-CSRFToken" csrftoken]
       (Http.jsonBody encoded_signup_params)
       signUpRespDecoder
  in
    Http.send Submitted req

init : UnAuthedUserFlags -> (Model, Cmd Msg)
init flags = ({
    flags = flags
  , signup_params = {
      email=""
    , password=""
    , confirm_password=""
    , invite_code=""
  }
  , show_passwords = False
  , errors = Dict.fromList [] }, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    ToggleShowPassword ->
      (SignUp.toggle_show_password model, Cmd.none)

    UpdatePassword password ->
      (SignUp.update_password model password, Cmd.none)

    UpdateConfirmPassword confirm_password ->
      (SignUp.update_confirm_password model confirm_password, Cmd.none)

    UpdateEmail addr ->
      (SignUp.update_email model addr, Cmd.none)

    UpdateInviteCode invite_code ->
      (updateInviteCode model invite_code, Cmd.none)

    Submit ->
      (model, post_signup model.flags.csrftoken model.signup_params)

    Submitted (Ok resp) ->
      (model, Navigation.load resp.redirect)

    Submitted (Err err) ->
      case err of
        Http.BadStatus resp ->
          case (Decode.decodeString (Decode.dict Decode.string) resp.body) of
            Ok errors ->
              ({ model | errors = errors }, Cmd.none)

            _ ->
              (model, Cmd.none)

        Http.BadPayload err resp ->
          (model, Cmd.none)

        _ ->
          (model, Cmd.none)

    Logout msg ->
      (model, Cmd.none)

isValidInviteCodeLength : InviteCode -> (Bool, Maybe String)
isValidInviteCodeLength invite_code =
  case String.length invite_code > 64 of
    True ->
      (False, Just "too long")

    False ->
      case String.length invite_code < 64 of
        True ->
          (False, Just "too short")

        False ->
          (True, Nothing)

updateInviteCode : Model -> InviteCode -> Model
updateInviteCode model invite_code =
  let
    signup_params = model.signup_params
    (valid_invite_code, invite_code_err) = isValidInviteCodeLength invite_code
  in
    { model
    | signup_params = { signup_params | invite_code = invite_code }
    , errors =
        (if (valid_invite_code) || (invite_code == "") then
          Dict.remove "invite_code" model.errors
         else
          Dict.insert
            "invite_code" ("This invite code is " ++ (Maybe.withDefault "" invite_code_err) ++ ".") model.errors)
    }

view_invite_code_input : Model -> List (Html Msg)
view_invite_code_input model =
  let
    err = Dict.member "invite_code" model.errors

    err_msg = [
      SignUp.signup_label
        (Html.em [] [Html.text (Maybe.withDefault "" (Dict.get "invite_code" model.errors))]) ]
  in [
     SignUp.signup_label (Html.span [] [ Html.text "Invite Code " ])
   , Html.input
       ([attribute "size" "25", onInput UpdateInviteCode] ++
       (if err then [attribute "class" "input_error"] else [])) []
   ] ++ (if err then err_msg else [])

instructor_signup_view : Model -> Html Msg
instructor_signup_view model =
  div [] [
    Views.view_unauthed_header
  , div [ classList [("signup", True)] ] [
      div [class "signup_title"] [ Html.text "Instructor Signup" ]
    , div [classList [("signup_box", True)] ] <|
      (SignUp.view_email_input UpdateEmail model) ++
      (SignUp.view_password_input (ToggleShowPassword, UpdatePassword, UpdateConfirmPassword) model) ++
      view_invite_code_input model ++
      (SignUp.view_submit Submit model)
    ]
  , Views.view_footer
  ]

main : Program UnAuthedUserFlags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = instructor_signup_view
    , subscriptions = subscriptions
    , update = update
    }
