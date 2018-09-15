import ForgotPassword exposing (PassResetConfirmResp, Password, ResetPassURI, UserEmail, forgotPassConfirmRespDecoder)

import Html exposing (Html, div, span)
import Html.Attributes exposing (class, classList, attribute)
import Html.Events exposing (on, onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Http exposing (..)
import HttpHelpers exposing (post_with_headers)
import Json.Decode as Decode

import Dict exposing (Dict)

import Json.Encode as Encode

import Config

import Views
import Flags

import Navigation


type alias Flags = { csrftoken : Flags.CSRFToken, uidb64: String, validlink : Bool }

type Msg =
    Submit
  | Submitted (Result Http.Error PassResetConfirmResp)
  | UpdatePassword String
  | UpdatePasswordConfirm String
  | ToggleShowPassword Bool

type alias Model = {
    flags : Flags
  , password : String
  , confirm_password : String
  , show_password : Bool
  , resp : PassResetConfirmResp
  , errors : Dict String String }

init : Flags -> (Model, Cmd Msg)
init flags = ({
    flags = flags
  , password = ""
  , confirm_password = ""
  , show_password = False
  , resp = ForgotPassword.emptyPassResetResp
  , errors = Dict.fromList [] }, Cmd.none)

reset_pass_encoder : Password -> Encode.Value
reset_pass_encoder password =
  Encode.object [
    ("new_password1", Encode.string password.password)
  , ("new_password2", Encode.string password.confirm_password)
  , ("uidb64", Encode.string password.uidb64)
  ]

post_passwd_reset : ResetPassURI -> Flags.CSRFToken -> Password -> Cmd Msg
post_passwd_reset reset_pass_endpoint csrftoken password =
  let
    encoded_login_params = reset_pass_encoder password
    req =
      post_with_headers
         reset_pass_endpoint
         [Http.header "X-CSRFToken" csrftoken]
         (Http.jsonBody encoded_login_params)
         forgotPassConfirmRespDecoder
  in
    Http.send Submitted req

update : ResetPassURI -> Msg -> Model -> (Model, Cmd Msg)
update endpoint msg model =
  case msg of
    ToggleShowPassword toggle ->
      ({ model | show_password = not model.show_password }, Cmd.none)

    UpdatePassword pass ->
      ({ model |
         password = pass
       , resp = ForgotPassword.emptyPassResetResp
       , errors = Dict.fromList (if pass /= model.confirm_password then [("all", "Passwords must match")] else [])
       }, Cmd.none)

    UpdatePasswordConfirm confirm_pass ->
      ({ model |
         confirm_password = confirm_pass
       , resp = ForgotPassword.emptyPassResetResp
       , errors = Dict.fromList (if confirm_pass /= model.password then [("all", "Passwords must match")] else [])
       }, Cmd.none)

    Submit ->
      ({ model | errors = Dict.fromList [] }
       , post_passwd_reset endpoint model.flags.csrftoken
           (Password model.password model.confirm_password model.flags.uidb64))

    Submitted (Ok resp) ->
      ({ model | resp = resp }, Navigation.load resp.redirect)

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

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view Config.reset_pass_endpoint
    , subscriptions = subscriptions
    , update = update Config.reset_pass_endpoint
    }

login_label : (List (Html.Attribute Msg)) -> Html Msg -> Html Msg
login_label attributes html =
  div ([attribute "class" "login_label"] ++ attributes) [
    html
  ]

view_errors : Model -> List (Html Msg)
view_errors model =
  case Dict.get "all" model.errors of
    Just all_err ->
      [ login_label [] (span [attribute "class" "errors"] [ Html.em [] [Html.text <| all_err ]]) ]
    _ ->
      [ span [attribute "class" "errors"] [] ]

view_submit : Model -> List (Html Msg)
view_submit model =
  let
    has_error = Dict.member "password" model.errors || Dict.member "confirm_password" model.errors
    empty_passwds = String.isEmpty model.password && String.isEmpty model.confirm_password
    passwords_match = model.password == model.confirm_password

    button_disabled =
      if has_error || empty_passwds || (not passwords_match) then
        [class "disabled"]
      else
        [onClick Submit, class "cursor"]
  in [
    login_label ([class "button"] ++ button_disabled)
      (div [class "login_submit"] [ span [] [ Html.text "Change Password" ] ])
  ]

view_resp : PassResetConfirmResp -> Html Msg
view_resp reset_pass_resp =
  if (not (String.isEmpty reset_pass_resp.body)) then
    div [class "msg"] [
      span [] [ Html.text reset_pass_resp.body ]
    ]
  else
    Html.text ""

view_password_input : Model -> List (Html Msg)
view_password_input model =
  let
    err_msg =
      case Dict.get "password" model.errors of
       Just err_msg ->
         login_label [] (Html.em [] [Html.text err_msg])

       Nothing ->
         Html.text ""

    passwd_error =
      if (Dict.member "password" model.errors || Dict.member "all" model.errors) then
        [attribute "class" "input_error"]
      else
        []

    show_passwd = if model.show_password then [] else [attribute "type" "password"]
  in [
      login_label [] (span [] [ Html.text "Set a new password" ])
    , Html.input ([
        attribute "size" "25"
      , onInput UpdatePassword ] ++ passwd_error ++ show_passwd) []
      , err_msg
      , view_resp model.resp
    ]

view_password_confirm_input : Model -> List (Html Msg)
view_password_confirm_input model =
  let
    err_msg =
      case Dict.get "confirm_password" model.errors of
       Just err_msg ->
         login_label [] (Html.em [] [Html.text err_msg])

       Nothing ->
         Html.text ""

    passwd_error =
      if (Dict.member "confirm_password" model.errors || Dict.member "all" model.errors) then
        [attribute "class" "input_error"]
      else
        []

    show_passwd = if model.show_password then [] else [attribute "type" "password"]
  in [
      login_label [] (span [] [ Html.text "Confirm Password" ])
    , Html.input ([
        attribute "size" "25"
      , onInput UpdatePasswordConfirm ] ++ passwd_error ++ show_passwd) []
      , err_msg
      , view_resp model.resp
    ]

view_show_passwd_toggle : Model -> List (Html Msg)
view_show_passwd_toggle model =
  [
    span [] [
      Html.input
        ([attribute "type" "checkbox", onCheck ToggleShowPassword] ++
          (if model.show_password then [attribute "checked" "true"] else []) ) []
    , Html.text "Show Password"
    ]
  ]


view_content : Model -> Html Msg
view_content model =
  div [ classList [("login", True)] ] [
    div [class "login_box"] <|
      view_password_input model ++
      view_password_confirm_input model ++
      view_errors model ++
      view_show_passwd_toggle model ++
      view_submit model
  ]

view : ResetPassURI -> Model -> Html Msg
view reset_pass_uri model =
  div [] [
    Views.view_unauthed_header
  , view_content model
  , Views.view_footer
  ]
