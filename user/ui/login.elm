import Html exposing (Html, div)
import Html.Attributes exposing (classList, attribute)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Http exposing (..)
import HttpHelpers exposing (post_with_headers)
import Json.Decode as Decode

import Array exposing (Array)
import Json.Encode as Encode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

import Views exposing (view_filter, view_header, view_footer)
import Config exposing (signup_api_endpoint)
import Flags exposing (CSRFToken, Flags)


type alias UserID = Int

type alias SignUpResp = { id: Maybe UserID }

-- UPDATE
type Msg = Submit | Submitted (Result Http.Error SignUpResp)

type alias SignUpParams = {
    email : String
  , password : String
  , verify_password : String }

type alias Model = {
    signup_params : Maybe SignUpParams }

signUpEncoder : SignUpParams -> Encode.Value
signUpEncoder model = Encode.object [
     ("email", Encode.string model.email)
   , ("password", Encode.string model.password)
   , ("verify_password", Encode.string model.verify_password)
  ]

signUpRespDecoder : Decode.Decoder (SignUpResp)
signUpRespDecoder =
  decode SignUpResp
    |> optional "id" (Decode.maybe Decode.int) Nothing

init : Flags -> (Model, Cmd Msg)
init flags = (Model Nothing, Cmd.none)

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
update msg model = (model, Cmd.none)

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

view_email_input : Model -> List (Html Msg)
view_email_input model = [
    Html.text "Email Address"
  , Html.input [attribute "size" "25"] []
  ]

view_password_input : Model -> List (Html Msg)
view_password_input model = [
    Html.text "Password"
  , Html.input [attribute "size" "35"] []
  , Html.text "Password (verify)"
  , Html.input [attribute "size" "35"] []
  ]

view_submit : Model -> List (Html Msg)
view_submit model = [
    Html.text "Sign Up"
  ]


view_content : Model -> Html Msg
view_content model = Html.div [ classList [("signup", True)] ] [
    Html.div [classList [("signup_box", True)] ] <|
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
