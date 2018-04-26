import Html exposing (Html, div)
import Flags exposing (CSRFToken)

import SignUp
import Navigation
import Dict exposing (Dict)
import Json.Encode as Encode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)
import Json.Decode as Decode
import Views exposing (view_filter, view_header, view_footer)
import Html.Attributes exposing (classList, attribute)

import HttpHelpers exposing (post_with_headers)
import Config exposing (student_signup_api_endpoint)
import Http exposing (..)
import Model exposing (TextDifficulty)
import Html.Events exposing (onClick, onBlur, onInput)

type alias SignUpResp = { id: SignUp.UserID, redirect: SignUp.URI }

type alias Flags = { csrftoken : CSRFToken, difficulties: List TextDifficulty }

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

post_signup : CSRFToken -> SignUpParams -> Cmd Msg
post_signup csrftoken signup_params =
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
update msg model = case msg of
  ToggleShowPassword -> (SignUp.toggle_show_password model, Cmd.none)
  UpdatePassword password -> (SignUp.update_password model password, Cmd.none)
  UpdateConfirmPassword confirm_password -> (SignUp.update_confirm_password model confirm_password, Cmd.none)
  UpdateEmail addr -> (SignUp.update_email model addr, Cmd.none)

  UpdateDifficulty difficulty -> let
      signup_params = model.signup_params
    in
      ({ model | signup_params = { signup_params | difficulty = difficulty } }, Cmd.none)

  Submit -> (SignUp.submit model, post_signup model.flags.csrftoken model.signup_params)
  Submitted (Ok resp) -> (model, Navigation.load resp.redirect)
  Submitted (Err err) -> case err of
      Http.BadStatus resp -> case (Decode.decodeString (Decode.dict Decode.string) resp.body) of
        Ok errors -> ({ model | errors = errors }, Cmd.none)
        _ -> (model, Cmd.none)
      Http.BadPayload err resp -> (model, Cmd.none)
      _ -> (model, Cmd.none)

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

view_content : Model -> Html Msg
view_content model = Html.div [ classList [("signup", True)] ] [
    Html.div [classList [("signup_box", True)] ] <|
        (SignUp.view_email_input UpdateEmail model) ++
        (SignUp.view_password_input (ToggleShowPassword, UpdatePassword, UpdateConfirmPassword) model) ++
        (view_difficulty_choices model) ++
        (SignUp.view_submit Submit model)
  ]

view : Model -> Html Msg
view model = div [] [
    (view_header)
  , (view_filter)
  , (view_content model)
  , (view_footer)
  ]

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }
