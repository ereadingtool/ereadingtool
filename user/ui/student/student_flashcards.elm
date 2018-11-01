import Html exposing (Html, div, span)
import Html.Attributes exposing (class, classList, attribute)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Http exposing (..)
import HttpHelpers

import Json.Encode
import Json.Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)


import Dict exposing (Dict)

import Profile

import Text.Reading.Model exposing (TextReading, TextReadingScore)

import Student.Profile.Model exposing (StudentProfile)
import Student.Profile.Encode

import Config
import Views
import Flags

import Ports

import Menu.Msg as MenuMsg
import Menu.Logout

import HtmlParser
import HtmlParser.Util


-- UPDATE
type Msg =
    RetrieveStudentProfile (Result Error StudentProfile)
  -- site-wide messages
  | Logout MenuMsg.Msg
  | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)

type alias Flags = Flags.Flags {}

type alias Model = {
    flags : Flags
  , profile : StudentProfile
  , err_str : String
  , errors : Dict String String }

username_valid_encode : String -> Json.Encode.Value
username_valid_encode username =
  Json.Encode.object [("username", Json.Encode.string username)]

init : Flags -> (Model, Cmd Msg)
init flags = ({
    flags = flags
  , profile = Student.Profile.Model.emptyStudentProfile
  , err_str = "", errors = Dict.fromList [] }, Profile.retrieve_student_profile RetrieveStudentProfile flags.profile_id)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  RetrieveStudentProfile (Ok profile) ->
    ({ model | profile = profile}, Cmd.none)

  -- handle user-friendly msgs
  RetrieveStudentProfile (Err err) ->
    ({ model | err_str = toString err }, Cmd.none)

  Logout msg ->
    (model, Student.Profile.Model.logout model.profile model.flags.csrftoken LoggedOut)

  LoggedOut (Ok logout_resp) ->
    (model, Ports.redirect logout_resp.redirect)

  LoggedOut (Err err) -> let _ = Debug.log "log out error" err in
      (model, Cmd.none)



main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }


view_content : Model -> Html Msg
view_content model =
  div [ classList [("flashcards", True)] ] [
  ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    Views.view_header (Profile.fromStudentProfile model.profile) Nothing Logout
  , view_content model
  , Views.view_footer
  ]
