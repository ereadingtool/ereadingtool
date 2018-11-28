import Html exposing (Html, div, span)
import Html.Attributes exposing (class, classList, attribute)

import Http exposing (..)

import Dict exposing (Dict)

import User.Profile

import Student.Profile exposing (StudentProfile)
import Views
import Profile.Flags

import Ports

import Menu.Msg as MenuMsg
import Menu.Logout


-- UPDATE
type Msg =
    RetrieveStudentProfile (Result Error StudentProfile)
  -- site-wide messages
  | Logout MenuMsg.Msg
  | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)

type alias Flags = Profile.Flags.Flags {}

type alias Model = {
    flags : Flags
  , profile : StudentProfile
  , err_str : String
  , errors : Dict String String }

init : Flags -> (Model, Cmd Msg)
init flags = ({
    flags = flags
  , profile = Student.Profile.emptyStudentProfile
  , err_str = "", errors = Dict.fromList [] }
  , User.Profile.retrieve_student_profile RetrieveStudentProfile flags.profile_id)

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
    (model, Student.Profile.logout model.profile model.flags.csrftoken LoggedOut)

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
  let
    flashcards = Student.Profile.studentFlashcards model.profile
  in
    div [ classList [("flashcards", True)] ] [
    ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    Views.view_authed_header (User.Profile.fromStudentProfile model.profile) Nothing Logout
  , view_content model
  , Views.view_footer
  ]
