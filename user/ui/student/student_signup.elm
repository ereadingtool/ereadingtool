import Html exposing (Html, div, span)
import Flags

import SignUp
import Navigation
import Dict exposing (Dict)
import Json.Encode as Encode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)
import Json.Decode as Decode
import Views
import Html.Attributes exposing (classList, class, attribute)

import HttpHelpers exposing (post_with_headers)
import Config exposing (student_signup_api_endpoint)
import Http exposing (..)
import Text.Model exposing (TextDifficulty)
import Html.Events exposing (onClick, onBlur, onInput)

import Menu.Msg as MenuMsg

type alias SignUpResp = { id: SignUp.UserID, redirect: SignUp.URI }

type alias Flags = { csrftoken : Flags.CSRFToken, difficulties: List TextDifficulty }

type alias SignUpParams = {
    email : String
  , password : String
  , confirm_password : String
  , difficulty : String }

type Msg =
    ToggleShowPassword
  | UpdateEmail String
  | UpdatePassword String
  | UpdateConfirmPassword String
  | UpdateDifficulty String
  | Submitted (Result Http.Error SignUpResp)
  | Submit
  | Logout MenuMsg.Msg

type alias Model = {
    flags : Flags
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
   , ("difficulty", Encode.string signup_params.difficulty)
  ]

signUpRespDecoder : Decode.Decoder (SignUpResp)
signUpRespDecoder =
  decode SignUpResp
    |> required "id" Decode.int
    |> required "redirect" Decode.string

postSignup : Flags.CSRFToken -> SignUpParams -> Cmd Msg
postSignup csrftoken signup_params =
  let encoded_signup_params = signUpEncoder signup_params
      req =
    post_with_headers
       student_signup_api_endpoint
       [Http.header "X-CSRFToken" csrftoken]
       (Http.jsonBody encoded_signup_params)
       signUpRespDecoder
  in
    Http.send Submitted req

init : Flags -> (Model, Cmd Msg)
init flags = ({
    flags = flags
  , signup_params = {
      email=""
    , password=""
    , confirm_password=""
    , difficulty=(case List.head flags.difficulties of
      Just (difficulty_key, difficulty_name) -> difficulty_key
      _ -> "")
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

    UpdateDifficulty difficulty ->
      let
        signup_params = model.signup_params
      in
        ({ model | signup_params = { signup_params | difficulty = difficulty } }, Cmd.none)

    Submit ->
      (SignUp.submit model, postSignup model.flags.csrftoken model.signup_params)

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
        Http.BadPayload err resp -> (model, Cmd.none)
        _ ->
          (model, Cmd.none)

    Logout msg ->
      (model, Cmd.none)

view_difficulty_choices : Model -> List (Html Msg)
view_difficulty_choices model = [
      SignUp.signup_label (Html.text "Choose a preferred difficulty:")
    , Html.select [
         onInput UpdateDifficulty ] [
        Html.optgroup [] (List.map (\(k,v) ->
          Html.option ([attribute "value" k] ++
            (if v == model.signup_params.difficulty then [attribute "selected" ""] else []))
           [ Html.text v ]) model.flags.difficulties)
       ]
    ]

view_student_welcome_msg : Html Msg
view_student_welcome_msg =
  let
    welcome_title =
      """Welcome to The Language Flagship’s Steps To Advanced Reading (STAR) website."""
    welcome_msg =
     """
     The purpose of this site is to help students improve their reading proficiency in Flagship language that they
     are studying. This site includes a wide range of texts at different proficiency levels.
     You will select texts to read by proficiency level and by topic.
     Before reading the Russian texts, you will get a brief contextualizing message in English.
     Then you will see the first part of the text followed by comprehension questions.
     Once you’ve read the text and selected the best answer, you will get feedback telling you if your choice is
     correct, and why or why not. The format of this site resembles the Flagship proficiency tests, and our goal is to
      help you build your reading skills for those tests. Any particular reading should take you between 5-15 minutes
      to complete, and we envision that you can use these texts on the go, when commuting, when waiting for a bus, etc.
      You can come back to texts at any time.  If this is your first time using the website, pop-up boxes will help
      you learn how to use the site."""
  in
    div [class "welcome_msg"] [
      span [class "headline"] [ Html.text welcome_title ]
    , div [class "msg"] [Html.text welcome_msg]
    ]

view_content : Model -> Html Msg
view_content model =
  div [ classList [("signup", True)] ] [
    div [class "signup_title"] [Html.text "Student Signup"]
  , view_student_welcome_msg
  , div [classList [("signup_box", True)] ] <|
      (SignUp.view_email_input UpdateEmail model) ++
      (SignUp.view_password_input (ToggleShowPassword, UpdatePassword, UpdateConfirmPassword) model) ++
      (view_difficulty_choices model) ++
      (SignUp.view_submit Submit model)
  ]

view : Model -> Html Msg
view model = div [] [
    Views.view_unauthed_header
  , view_content model
  , Views.view_footer
  ]

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }
