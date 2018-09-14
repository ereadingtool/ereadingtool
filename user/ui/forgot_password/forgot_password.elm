import ForgotPassword exposing (ForgotPassResp, ForgotPassURI, UserEmail, forgotRespDecoder)

import Html exposing (Html, div, span)
import Html.Attributes exposing (class, classList, attribute)
import Html.Events exposing (on, onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Http exposing (..)
import HttpHelpers exposing (post_with_headers)
import Json.Decode as Decode

import Dict exposing (Dict)

import Util exposing (is_valid_email)

import Json.Encode as Encode

import Config

import Views
import Flags

import Util


type Msg =
    Submit
  | Submitted (Result Http.Error ForgotPassResp)
  | UpdateEmail String

type alias Model = {
    flags : Flags.UnAuthedFlags
  , user_email : UserEmail
  , resp : ForgotPassResp
  , errors : Dict String String }

init : Flags.UnAuthedFlags -> (Model, Cmd Msg)
init flags = ({
    flags = flags
  , user_email = ""
  , resp = ForgotPassword.emptyForgotPassResp
  , errors = Dict.fromList [] }, Cmd.none)

forgot_pass_encoder : UserEmail -> Encode.Value
forgot_pass_encoder user_email =
  Encode.object [
    ("email", Encode.string user_email)
  ]

post_forgot_pass : ForgotPassURI -> Flags.CSRFToken -> UserEmail -> Cmd Msg
post_forgot_pass forgot_pass_endpoint csrftoken user_email =
  let
    encoded_login_params = forgot_pass_encoder user_email
    req =
      post_with_headers
         forgot_pass_endpoint
         [Http.header "X-CSRFToken" csrftoken]
         (Http.jsonBody encoded_login_params)
         forgotRespDecoder
  in
    Http.send Submitted req

update : ForgotPassURI -> Msg -> Model -> (Model, Cmd Msg)
update endpoint msg model =
  case msg of
    UpdateEmail addr ->
      ({ model | user_email = addr
       , resp = ForgotPassword.emptyForgotPassResp
       , errors =
           (if (is_valid_email addr) || (addr == "") then
             Dict.remove "email" model.errors
            else
              Dict.insert "email" "This e-mail is invalid" model.errors)
         }, Cmd.none)

    Submit ->
      ({ model | errors = Dict.fromList [] }
       , post_forgot_pass endpoint model.flags.csrftoken model.user_email)

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

main : Program Flags.UnAuthedFlags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view Config.forgot_pass_endpoint
    , subscriptions = subscriptions
    , update = update Config.forgot_pass_endpoint
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
      if has_error || String.isEmpty model.user_email then
        [class "disabled"]
      else
        [onClick Submit, class "cursor"]
  in [
    login_label ([class "button"] ++ button_disabled)
      (div [class "login_submit"] [ span [] [ Html.text "Forgot Password" ] ])
  ]

view_resp : ForgotPassResp -> Html Msg
view_resp forgot_pass_resp =
  if (not (String.isEmpty forgot_pass_resp.body)) then
    div [class "msg"] [
      span [] [ Html.text forgot_pass_resp.body ]
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
      , onInput UpdateEmail ] ++ email_error) []
      , err_msg
      , view_resp model.resp
    ]

view_content : ForgotPassURI -> Model -> Html Msg
view_content login model =
  div [ classList [("login", True)] ] [
    div [class "login_box"] <|
      view_email_input model ++
      view_submit model ++
      view_errors model
  ]

view : ForgotPassURI -> Model -> Html Msg
view forgot_pass_uri model =
  div [] [
    Views.view_unauthed_header
  , view_content forgot_pass_uri model
  , Views.view_footer
  ]
