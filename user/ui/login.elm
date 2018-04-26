module Login exposing (init, view, subscriptions, update, Model, Msg)

import Html exposing (Html, div)
import Html.Attributes exposing (classList, attribute)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Http exposing (..)
import HttpHelpers exposing (post_with_headers)
import Json.Decode as Decode
import Navigation

import Dict exposing (Dict)

import Util exposing (is_valid_email)

import Json.Encode as Encode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

import Views exposing (view_filter, view_header, view_footer)
import Config exposing (student_login_api_endpoint)
import Flags exposing (CSRFToken, Flags)


type alias UserID = Int
type alias URI = String


type alias LoginResp = { id: UserID, redirect : URI }

-- UPDATE
type Msg =
    Submit
  | Submitted (Result Http.Error LoginResp)
  | UpdateEmail String
  | UpdatePassword String

type alias LoginParams = {
    username : String
  , password : String }

type alias Model = {
    flags : Flags
  , login_params : LoginParams
  , errors : Dict String String }

loginEncoder : LoginParams -> Encode.Value
loginEncoder login_params = Encode.object [
     ("username", Encode.string login_params.username)
   , ("password", Encode.string login_params.password)
  ]

loginRespDecoder : Decode.Decoder (LoginResp)
loginRespDecoder =
  decode LoginResp
    |> required "id" Decode.int
    |> required "redirect" Decode.string

init : Flags -> (Model, Cmd Msg)
init flags = ({
    flags = flags
  , login_params = (LoginParams "" "")
  , errors = Dict.fromList [] }, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

post_login : String -> CSRFToken -> LoginParams -> Cmd Msg
post_login endpoint csrftoken login_params =
  let encoded_login_params = loginEncoder login_params
      req =
    post_with_headers
       endpoint
       [Http.header "X-CSRFToken" csrftoken]
       (Http.jsonBody encoded_login_params)
       loginRespDecoder
  in
    Http.send Submitted req

update : String -> Msg -> Model -> (Model, Cmd Msg)
update endpoint msg model = case msg of
  UpdatePassword password -> let login_params = model.login_params in
        ({ model | login_params = { login_params | password = password } }, Cmd.none)
  UpdateEmail addr -> let login_params = model.login_params in
    ({ model | login_params = { login_params | username = addr }
             , errors = (if (is_valid_email addr) || (addr == "") then
                 Dict.remove "email" model.errors
               else
                 Dict.insert "email" "This e-mail is invalid" model.errors) }
             , Cmd.none)

  Submit -> ({ model | errors = Dict.fromList [] }, post_login endpoint model.flags.csrftoken model.login_params)

  Submitted (Ok resp) -> (model, Navigation.load resp.redirect)

  Submitted (Err err) -> case err of
      Http.BadStatus resp -> case (Decode.decodeString (Decode.dict Decode.string) resp.body) of
        Ok errors -> ({ model | errors = errors }, Cmd.none)
        _ -> (model, Cmd.none)
      Http.BadPayload err resp -> (model, Cmd.none)
      _ -> (model, Cmd.none)


login_label : Html Msg -> Html Msg
login_label html = Html.div [attribute "class" "login_label"] [ html ]

view_email_input : Model -> List (Html Msg)
view_email_input model =
  let err_msg = case Dict.get "email" model.errors of
    Just err_msg -> login_label (Html.em [] [Html.text err_msg])
    Nothing -> Html.text ""
  in
    let email_error = if (Dict.member "email" model.errors) then
      [attribute "class" "input_error"]
    else [] in [
      login_label (Html.text "Username (e-mail address):")
    , Html.input ([
        attribute "size" "25"
      , onInput UpdateEmail ] ++ (email_error)) []
      , err_msg
    ]

view_password_input : Model -> List (Html Msg)
view_password_input model = let
  password_err_msg = case Dict.get "password" model.errors of
    Just err_msg -> login_label (Html.em [] [Html.text err_msg])
    Nothing -> Html.text ""
  pass_err =
    (Dict.member "password" model.errors)
  attrs = [attribute "size" "35", attribute "type" "password"] ++
    (if pass_err then [attribute "class" "input_error"] else []) in [
    login_label (Html.span [] [
      Html.text "Password "
    ])
  , Html.input (attrs ++ [onInput UpdatePassword]) []
  , password_err_msg
  ]

view_submit : Model -> List (Html Msg)
view_submit model = [
    login_label (div [attribute "class" "login_submit"] [
      Html.span [classList [("cursor", True)], onClick Submit ] [ Html.text "Login" ]
    ])
  ]

view_content : Model -> Html Msg
view_content model = Html.div [ classList [("login", True)] ] [
    Html.div [classList [("login_box", True)] ] <|
        (view_email_input model) ++ (view_password_input model) ++ (view_submit model)
  ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    (view_header)
  , (view_filter)
  , (view_content model)
  , (view_footer)
  ]
