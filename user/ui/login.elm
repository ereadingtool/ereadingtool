module Login exposing (init, view, subscriptions, update, Model, Msg, student_login, instructor_login)

import Html exposing (Html, div, span)
import Html.Attributes exposing (class, classList, attribute)
import Html.Events exposing (on, onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

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

import Util
import Config


type alias UserID = Int
type alias URI = String
type alias SignUpURI = String
type alias LoginURI = String

type alias LoginResp = { id: UserID, redirect : URI }

-- UPDATE
type Msg =
    Submit
  | Submitted (Result Http.Error LoginResp)
  | UpdateEmail String
  | UpdatePassword String

type Login =
    StudentLogin SignUpURI LoginURI Int
  | InstructorLogin SignUpURI LoginURI Int

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
    StudentLogin uri _ _ ->
      uri

    InstructorLogin uri _ _ ->
      uri

label : Login -> String
label login =
  case login of
    StudentLogin _ _ _ ->
      "Student Login"

    InstructorLogin _ _ _ ->
      "Instructor Login"

menu_index : Login -> Int
menu_index login =
  case login of
    StudentLogin _ _ menu_index ->
      menu_index

    InstructorLogin _ _ menu_index ->
      menu_index

student_login : URI -> URI -> Int -> Login
student_login signup_uri login_uri menu_index =
  StudentLogin signup_uri login_uri menu_index

instructor_login : URI -> URI -> Int -> Login
instructor_login signup_uri login_uri menu_index =
  InstructorLogin signup_uri login_uri menu_index

loginEncoder : LoginParams -> Encode.Value
loginEncoder login_params =
  Encode.object [
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

login_label : (List (Html.Attribute Msg)) -> Html Msg -> Html Msg
login_label attributes html =
  div ([attribute "class" "login_label"] ++ attributes) [
    html
  ]

view_email_input : Model -> List (Html Msg)
view_email_input model =
  let err_msg =
    case Dict.get "email" model.errors of
       Just err_msg ->
         login_label [] (Html.em [] [Html.text err_msg])
       Nothing ->
         Html.text ""
  in
    let email_error = if (Dict.member "email" model.errors) then
      [attribute "class" "input_error"]
    else [] in [
      login_label [] (span [] [ Html.text "Username (e-mail address):" ])
    , Html.input ([
        attribute "size" "25"
      , onInput UpdateEmail ] ++ (email_error)) []
      , err_msg
    ]

view_password_input : Model -> List (Html Msg)
view_password_input model =
  let
    password_err_msg =
      case Dict.get "password" model.errors of
        Just err_msg ->
          login_label [] (Html.em [] [Html.text err_msg])
        Nothing ->
          Html.text ""

    pass_err =
      (Dict.member "password" model.errors)

    attrs =
      [attribute "size" "35", attribute "type" "password"] ++
      (if pass_err then [attribute "class" "input_error"] else [])

  in [
    login_label [] (span [] [
      Html.text "Password:"
    ])
    , Html.input (attrs ++ [onInput UpdatePassword, Util.onEnterUp Submit]) []
    , password_err_msg
    ]

view_errors : Model -> List (Html Msg)
view_errors model =
  case Dict.get "all" model.errors of
    Just all_err ->
      [ login_label [] (span [attribute "class" "errors"] [ Html.em [] [Html.text <| all_err ]]) ]
    _ ->
      [ span [attribute "class" "errors"] [] ]

view_submit : Model -> List (Html Msg)
view_submit model = [
    login_label [class "button", onClick Submit, class "cursor"]
      (div [class "login_submit"] [ span [] [ Html.text "Login" ] ])
  ]

view_other_login_option : Login -> Html Msg
view_other_login_option login =
  case login of
    StudentLogin _ _ _ ->
      div [] [
        Html.text "Are you an instructor? "
      , Html.a [attribute "href" Config.instructor_login_page] [
          span [attribute "class" "cursor"] [
            Html.text "Login as an instructor"
          ]
        ]
      ]
    InstructorLogin _ _ _ ->
      div [] [
        Html.text "Are you a student? "
      , Html.a [attribute "href" Config.student_login_page] [
          span [attribute "class" "cursor"] [
            Html.text "Login as an student"
          ]
        ]
      ]

view_login : Login -> List (Html Msg)
view_login login =
  [
    span [class "login_options"] [
      div [] [
         Html.text "Not registered? "
      ,  Html.a [attribute "href" (signup_uri login)] [ span [attribute "class" "cursor"] [Html.text "Sign Up"]]
      ]
    , div [] [
        Html.text "Forgot Password? "
      , Html.a [attribute "href" Config.forgot_password_page] [
          span [attribute "class" "cursor"] [
            Html.text "Reset Password"
          ]
        ]
      ]
    , view_other_login_option login
    ]
  ]

view_content : Login -> Model -> Html Msg
view_content login model =
  div [ classList [("login", True)] ] [
    div [class "login_type"] [ Html.text (label login) ]
  , div [classList [("login_box", True)] ] <|
      (view_email_input model) ++
      (view_password_input model) ++ (view_login login) ++
      (view_submit model) ++
      (view_errors model)
  ]

-- VIEW
view : Login -> Model -> Html Msg
view login model =
  div [] [
    Views.view_unauthed_header
  , view_content login model
  , Views.view_footer
  ]
