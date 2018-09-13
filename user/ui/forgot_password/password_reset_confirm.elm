import ForgotPassword exposing (PassResetConfirmResp, Password, ResetPassURI, UserEmail, forgotRespDecoder)

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


type alias Flags = { csrftoken : Flags.CSRFToken, validlink : Bool }

type Msg =
    Submit
  | Submitted (Result Http.Error PassResetConfirmResp)
  | UpdatePassword String
  | UpdatePasswordConfirm String

type alias Model = {
    flags : Flags
  , password : String
  , confirm_password : String
  , resp : PassResetConfirmResp
  , errors : Dict String String }

init : Flags -> (Model, Cmd Msg)
init flags = ({
    flags = flags
  , password = ""
  , confirm_password = ""
  , resp = {errors=Dict.fromList [], body=""}
  , errors = Dict.fromList [] }, Cmd.none)

reset_pass_encoder : Password -> Encode.Value
reset_pass_encoder password =
  Encode.object [
    ("password", Encode.string (Tuple.first password))
  , ("confirm_password", Encode.string (Tuple.second password))
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
         forgotRespDecoder
  in
    Http.send Submitted req

update : ResetPassURI -> Msg -> Model -> (Model, Cmd Msg)
update endpoint msg model =
  case msg of
    UpdatePassword pass ->
      ({ model | password = pass
       , resp = {errors=Dict.fromList [], body=""}
       , errors = Dict.fromList []
         }, Cmd.none)

    UpdatePasswordConfirm pass ->
      ({ model | confirm_password = pass
       , resp = {errors=Dict.fromList [], body=""}
       , errors = Dict.fromList []
         }, Cmd.none)

    Submit ->
      ({ model | errors = Dict.fromList [] }
       , post_passwd_reset endpoint model.flags.csrftoken (model.password, model.confirm_password))

    Submitted (Ok resp) ->
      let
        new_errors = Dict.fromList <| Dict.toList model.errors ++ Dict.toList resp.errors
      in
        ({ model | errors = new_errors, resp = resp }, Cmd.none)

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
    has_error = Dict.member "email" model.errors

    button_disabled =
      if has_error || String.isEmpty model.password then
        [class "disabled"]
      else
        [onClick Submit, class "cursor"]
  in [
    login_label ([class "button"] ++ button_disabled)
      (div [class "login_submit"] [ span [] [ Html.text "Forgot Password" ] ])
  ]

view_resp : PassResetConfirmResp -> Html Msg
view_resp reset_pass_resp =
  if (not (String.isEmpty reset_pass_resp.body)) then
    div [class "msg"] [
      span [] [ Html.text reset_pass_resp.body ]
    ]
  else
    Html.text ""

view_email_input : Model -> List (Html Msg)
view_email_input model =
  let
    err_msg =
      case Dict.get "email" model.errors of
       Just err_msg ->
         login_label [] (Html.em [] [Html.text err_msg])

       Nothing ->
         Html.text ""

    email_error =
      if Dict.member "email" model.errors then
        [attribute "class" "input_error"]
      else
        []
  in [
      login_label [] (span [] [ Html.text "Username (e-mail address):" ])
    , Html.input ([
        attribute "size" "25"
      , onInput UpdatePassword ] ++ email_error) []
      , err_msg
      , view_resp model.resp
    ]

view_content : Model -> Html Msg
view_content model =
  div [ classList [("login", True)] ] [
    div [class "login_box"] <|
      view_email_input model ++
      view_submit model ++
      view_errors model
  ]

view : ResetPassURI -> Model -> Html Msg
view reset_pass_uri model =
  div [] [
    Views.view_unauthed_header
  , view_content model
  , Views.view_footer
  ]
