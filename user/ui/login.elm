import Html exposing (Html, div)
import Html.Attributes exposing (classList, attribute)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Http exposing (..)
import HttpHelpers exposing (post_with_headers)
import Json.Decode as Decode

import Dict exposing (Dict)

import Util exposing (is_valid_email)

import Json.Encode as Encode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

import Views exposing (view_filter, view_header, view_footer)
import Config exposing (signup_api_endpoint)
import Flags exposing (CSRFToken, Flags)


type alias UserID = Int

type alias SignUpResp = { id: Maybe UserID }

-- UPDATE
type Msg =
    Submit
  | Submitted (Result Http.Error SignUpResp)
  | ToggleShowPassword
  | UpdateEmail String
  | UpdatePassword String
  | UpdateConfirmPassword String

type alias SignUpParams = {
    email : String
  , password : String
  , confirm_password : String }

type alias Model = {
    flags : Flags
  , signup_params : SignUpParams
  , show_passwords : Bool
  , passwords_match : Bool
  , valid_email : Bool
  , errors : Maybe (Dict String String) }

signUpEncoder : SignUpParams -> Encode.Value
signUpEncoder signup_params = Encode.object [
     ("email", Encode.string signup_params.email)
   , ("password", Encode.string signup_params.password)
   , ("confirm_password", Encode.string signup_params.confirm_password)
  ]

signUpRespDecoder : Decode.Decoder (SignUpResp)
signUpRespDecoder =
  decode SignUpResp
    |> optional "id" (Decode.maybe Decode.int) Nothing

init : Flags -> (Model, Cmd Msg)
init flags = ({
    flags = flags
  , signup_params = (SignUpParams "" "" "")
  , show_passwords = False
  , passwords_match = True
  , valid_email = True
  , errors = Nothing }, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

post_signup : CSRFToken -> SignUpParams -> Cmd Msg
post_signup csrftoken signup_params =
  let encoded_signup_params = signUpEncoder signup_params in
  let req =
    post_with_headers signup_api_endpoint [Http.header "X-CSRFToken" csrftoken] (Http.jsonBody encoded_signup_params)
    <| signUpRespDecoder
  in
    Http.send Submitted req

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  ToggleShowPassword -> ({model | show_passwords = (if model.show_passwords then False else True)}, Cmd.none)

  UpdatePassword password -> let signup_params = model.signup_params in
        ({ model | signup_params = { signup_params | password = password } }, Cmd.none)

  UpdateConfirmPassword confirm_password -> let signup_params = model.signup_params in
        ({ model | signup_params = { signup_params | confirm_password = confirm_password }
                 , passwords_match = (signup_params.password == confirm_password) }, Cmd.none)

  UpdateEmail addr -> let signup_params = model.signup_params in
    ({ model | signup_params = { signup_params | email = addr }
             , valid_email = is_valid_email addr }, Cmd.none)

  Submit -> (model, post_signup model.flags.csrftoken model.signup_params)

  Submitted (Ok resp) -> (model, Cmd.none)

  Submitted (Err err) -> case err of
      Http.BadStatus resp -> case (Decode.decodeString (Decode.dict Decode.string) resp.body) of
        Ok errors -> ({ model | errors = Just errors }, Cmd.none)
        _ -> (model, Cmd.none)
      Http.BadPayload err resp -> (model, Cmd.none)
      _ -> (model, Cmd.none)

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

signup_label : Html Msg -> Html Msg
signup_label html = Html.div [attribute "class" "signup_label"] [ html ]

view_email_input : Model -> List (Html Msg)
view_email_input model =
  let invalid_email_attr = if model.valid_email then [] else [attribute "class" "input_error"] in [
    signup_label (Html.text "Email Address")
  , Html.input ([
      attribute "size" "25"
    , onInput UpdateEmail ] ++ (invalid_email_attr)) []
  ]

view_password_match : Bool -> Html Msg
view_password_match match =
  if match then
    Html.span [] []
  else
    Html.span [] [ Html.em [] [ Html.text "passwords do not match" ] ]

view_password_input : Model -> List (Html Msg)
view_password_input model =
  let attrs = [attribute "size" "35"] ++ (if model.passwords_match then [] else [attribute "class" "input_error"]) ++
    (if model.show_passwords then [attribute "type" "text"] else [attribute "type" "password"]) in [
    signup_label (Html.span [] [
      Html.text "Password "
    , Html.span [onClick ToggleShowPassword, attribute "class" "cursor"] [Html.text "(show)"]
    ])
  , Html.input (attrs ++ [onInput UpdatePassword]) []
  , signup_label (Html.text "Confirm Password")
  , Html.input (attrs ++ [onInput UpdateConfirmPassword]) []
  , (view_password_match model.passwords_match)
  ]

view_errors : Model -> List (Html Msg)
view_errors model = case model.errors of
  Just errors -> [
    signup_label (Html.span [attribute "class" "errors"] [ Html.text <| toString errors ]) ]
  _ -> [ Html.span [attribute "class" "errors"] [] ]

view_submit : Model -> List (Html Msg)
view_submit model = [
    signup_label (Html.span [classList [("cursor", True)], onClick Submit ] [ Html.text "Sign Up" ])
  ]

view_content : Model -> Html Msg
view_content model = Html.div [ classList [("signup", True)] ] [
    Html.div [classList [("signup_box", True)] ] <|
        (view_email_input model) ++ (view_password_input model) ++ (view_submit model) ++ (view_errors model)
  ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    (view_header)
  , (view_filter)
  , (view_content model)
  , (view_footer)
  ]
