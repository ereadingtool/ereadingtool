module Login exposing (init, view, subscriptions, update, Model, Msg, student_login, instructor_login)

import Html exposing (Html, div)
import Html.Attributes exposing (class, classList, attribute)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Http exposing (..)
import HttpHelpers exposing (post_with_headers)
import Json.Decode as Decode
import Navigation

import Dict exposing (Dict)

import Util exposing (is_valid_email)

import Json.Encode as Encode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

import Views
import Flags

import Profile

import Menu.Msg as MenuMsg

type alias UserID = Int
type alias URI = String
type alias SignUpURI = String

type alias LoginResp = { id: UserID, redirect : URI }

-- UPDATE
type Msg =
    Submit
  | Submitted (Result Http.Error LoginResp)
  | UpdateEmail String
  | UpdatePassword String
  | Logout MenuMsg.Msg

type Login = StudentLogin SignUpURI Int | InstructorLogin SignUpURI Int

type alias LoginParams = {
    username : String
  , password : String }

type alias Model = {
    flags : Flags.UnAuthedFlags
  , login_params : LoginParams
  , errors : Dict String String }

signup_uri : Login -> URI
signup_uri login =
  case login of
    StudentLogin uri _ -> uri
    InstructorLogin uri _ -> uri

label : Login -> String
label login =
  case login of
    StudentLogin _ _ -> "Student Login"
    InstructorLogin _ _ -> "Instructor Login"

menu_index : Login -> Int
menu_index login =
  case login of
    StudentLogin _ menu_index -> menu_index
    InstructorLogin _ menu_index -> menu_index

student_login : URI -> Int -> Login
student_login signup_uri menu_index =
  StudentLogin signup_uri menu_index

instructor_login : URI -> Int -> Login
instructor_login signup_uri menu_index =
  InstructorLogin signup_uri menu_index

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

init : Flags.UnAuthedFlags -> (Model, Cmd Msg)
init flags = ({
    flags = flags
  , login_params = (LoginParams "" "")
  , errors = Dict.fromList [] }, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

post_login : String -> Flags.CSRFToken -> LoginParams -> Cmd Msg
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
update endpoint msg model =
  case msg of
    UpdatePassword password ->
      let
        login_params = model.login_params
      in
        ({ model | login_params = { login_params | password = password } }, Cmd.none)

    UpdateEmail addr ->
      let
        login_params = model.login_params
      in
        ({ model | login_params = { login_params | username = addr }
         , errors =
             (if (is_valid_email addr) || (addr == "") then
               Dict.remove "email" model.errors
              else
               Dict.insert "email" "This e-mail is invalid" model.errors)
         }, Cmd.none)

    Submit ->
      ({ model | errors = Dict.fromList [] }
       , post_login endpoint model.flags.csrftoken model.login_params)

    Submitted (Ok resp) ->
      (model, Navigation.load resp.redirect)

    Submitted (Err err) ->
      case err of
        Http.BadStatus resp ->
          case (Decode.decodeString (Decode.dict Decode.string) resp.body) of
            Ok errors -> ({ model | errors = errors }, Cmd.none)
            _ -> (model, Cmd.none)
        Http.BadPayload err resp -> (model, Cmd.none)
        _ -> (model, Cmd.none)

    Logout msg ->
      (model, Cmd.none)

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
      login_label (Html.span [] [ Html.text "Username (e-mail address):" ])
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
      Html.text "Password:"
    ])
  , Html.input (attrs ++ [onInput UpdatePassword]) []
  , password_err_msg
  ]

view_errors : Model -> List (Html Msg)
view_errors model =
  case Dict.get "all" model.errors of
    Just all_err ->
      [ login_label (Html.span [attribute "class" "errors"] [ Html.em [] [Html.text <| all_err ]]) ]
    _ ->
      [ Html.span [attribute "class" "errors"] [] ]

view_submit : Model -> List (Html Msg)
view_submit model = [
    login_label (div [classList [("login_submit", True), ("button", True)]] [
      Html.span [classList [("cursor", True)], onClick Submit ] [ Html.text "Login" ]
    ])
  ]

view_signup : SignUpURI -> List (Html Msg)
view_signup signup_uri = [
  Html.span [] [
    Html.text "Not registered? "
  , Html.a [attribute "href" signup_uri] [ Html.span [attribute "class" "cursor"] [Html.text "Sign Up"]]
  ]]

view_content : Login -> Model -> Html Msg
view_content login model =
  div [ classList [("login", True)] ] [
    div [class "login_type"] [ Html.text (label login) ]
  , div [classList [("login_box", True)] ] <|
      (view_email_input model) ++
      (view_password_input model) ++ (view_signup (signup_uri login)) ++
      (view_submit model) ++
      (view_errors model)
  ]

-- VIEW
view : Login -> Model -> Html Msg
view login model =
  div [] [
    (Views.view_header Profile.emptyProfile (Just <| menu_index login) Logout)
  , (Views.view_filter)
  , (view_content login model)
  , (Views.view_footer)
  ]
