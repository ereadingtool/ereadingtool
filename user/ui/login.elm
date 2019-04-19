module Login exposing (..)

import User

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
import User.Flags.UnAuthed exposing (UnAuthedUserFlags)

import Util
import Config


type alias LoginResp = { id: User.UserID, redirect : User.URI }

-- UPDATE
type Msg =
    Submit
  | Submitted (Result Http.Error LoginResp)
  | UpdateEmail String
  | UpdatePassword String

type Login =
    StudentLogin User.SignUpURI User.LoginURI User.LoginPageURL
  | InstructorLogin User.SignUpURI User.LoginURI User.LoginPageURL

type alias LoginParams = {
    username : String
  , password : String }

type alias Model = {
    flags : Flags.UnAuthedFlags
  , login_params : LoginParams
  , login: Login
  , errors : Dict String String }


flagsToLogin : UnAuthedUserFlags -> Login
flagsToLogin flags =
  case flags.user_type of
    "student" ->
      StudentLogin
        (User.SignUpURI flags.signup_uri)
        (User.LoginURI flags.login_uri)
        (User.LoginPageURL (User.URL flags.login_page_url))

    "instructor" ->
      InstructorLogin
        (User.SignUpURI flags.signup_uri)
        (User.LoginURI flags.login_uri)
        (User.LoginPageURL (User.URL flags.login_page_url))

signup_uri : Login -> User.URI
signup_uri login =
  case login of
    StudentLogin uri _ ->
      uri

    InstructorLogin uri _ ->
      uri

forgotPassURL : Login -> User.ForgotPassURL
forgotPassURL login =
  case login of
    StudentLogin _ _ login_page_url ->
      User.forgotPassURL login_page_url

    InstructorLogin _ _ login_page_url ->
      User.forgotPassURL login_page_url


loginPageURL : Login -> User.LoginPageURL
loginPageURL login =
  case login of
    StudentLogin _ _ login_page_url ->
      User.loginPageURL login_page_url

    InstructorLogin _ _ login_page_url ->
      User.loginPageURL login_page_url


label : Login -> String
label login =
  case login of
    StudentLogin _ _ ->
      "Student Login"

    InstructorLogin _ _ ->
      "Instructor Login"

student_login : User.URI -> User.URI -> Login
student_login signup_uri login_uri =
  StudentLogin signup_uri login_uri

instructor_login : User.URI -> User.URI -> Login
instructor_login signup_uri login_uri =
  InstructorLogin signup_uri login_uri

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
init flags =
  let
    login = flagsToLogin flags
  in
    ({
      flags = flags
    , login_params = (LoginParams "" "")
    , login = login
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

update : User.LoginURI -> Msg -> Model -> (Model, Cmd Msg)
update login_endpoint msg model =
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
       , post_login login_endpoint model.flags.csrftoken model.login_params)

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
      login_label [] (span [] [ Html.text "E-mail Address:" ])
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
    StudentLogin _ _ ->
      div [] [
        Html.text "Are you an instructor? "
      , Html.a [attribute "href" (User.urlToString (loginPageURL login))] [
          span [attribute "class" "cursor"] [
            Html.text "Login as an instructor"
          ]
        ]
      ]

    InstructorLogin _ _ ->
      div [] [
        Html.text "Are you a student? "
      , Html.a [attribute "href" (User.urlToString (loginPageURL login))] [
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
      , Html.a [attribute "href" (User.urlToString (forgotPassURL login))] [
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
view : Model -> Html Msg
view login model =
  div [] [
    Views.view_unauthed_header
  , view_content login model
  , Views.view_footer
  ]
