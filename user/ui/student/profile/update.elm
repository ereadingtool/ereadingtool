module Student.Profile.Update exposing (..)

import Http exposing (..)
import HttpHelpers

import Json.Decode

import Dict exposing (Dict)

import Student.Profile.Msg exposing (..)

import Student.Profile.Model exposing (Model)
import Student.Profile.Help

import Student.Profile exposing (StudentProfileParams)

import Student.Profile

import Student.Profile.Encode
import Student.Profile.Decode

import Config
import Flags

import Ports


validate_username : Flags.CSRFToken -> String -> Cmd Msg
validate_username csrftoken username =
  let
    req =
      HttpHelpers.post_with_headers
       Config.username_validation_api_endpoint
       [Http.header "X-CSRFToken" csrftoken]
       (Http.jsonBody (Student.Profile.Encode.username_valid_encode username))
       Student.Profile.Decode.username_valid_decoder
  in
    Http.send ValidUsername req

put_profile : Flags.CSRFToken -> Student.Profile.StudentProfile -> Cmd Msg
put_profile csrftoken student_profile =
  case Student.Profile.studentID student_profile of
    Just id ->
      let
        encoded_profile = Student.Profile.Encode.profileEncoder student_profile
        req =
          HttpHelpers.put_with_headers
           (Student.Profile.studentUpdateURI id)
           [Http.header "X-CSRFToken" csrftoken]
           (Http.jsonBody encoded_profile) Student.Profile.Decode.studentProfileDecoder
      in
        Http.send Submitted req
    Nothing ->
      Cmd.none

toggle_username_update : Model -> Model
toggle_username_update model =
  { model | editing =
      (if Dict.member "username" model.editing then
        Dict.remove "username" model.editing
       else Dict.insert "username" True model.editing) }

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  RetrieveStudentProfile (Ok profile) ->
    let
      username_update = model.username_update
      new_username_update = { username_update | username = Student.Profile.studentUserName profile }
    in
      ({ model | profile = profile, username_update = new_username_update }, Cmd.none)

  -- handle user-friendly msgs
  RetrieveStudentProfile (Err err) ->
    ({ model | err_str = toString err }, Cmd.none)

  UpdateUsername value ->
    let
      username_update = model.username_update
      new_username_update = { username_update | username = value }
    in
      ({ model | username_update = new_username_update }, validate_username model.flags.csrftoken value)

  ValidUsername (Ok username_update) ->
    ({ model | username_update = username_update }, Cmd.none)

  ValidUsername (Err err) ->
    case err of
      Http.BadStatus resp ->
        case (Json.Decode.decodeString (Json.Decode.dict Json.Decode.string) resp.body) of
          Ok errors ->
            ({ model | errors = errors }, Cmd.none)
          _ ->
            (model, Cmd.none)

      Http.BadPayload err resp -> let _ = Debug.log "bad payload" err in
        (model, Cmd.none)

      _ ->
        (model, Cmd.none)

  UpdateDifficulty difficulty ->
    let
      new_difficulty_preference = (difficulty, difficulty)
      new_student_profile = Student.Profile.setStudentDifficultyPreference model.profile new_difficulty_preference
    in
      (model, put_profile model.flags.csrftoken new_student_profile)

  ToggleUsernameUpdate ->
    (toggle_username_update model, Cmd.none)

  SubmitUsernameUpdate ->
    let
      profile = Student.Profile.setUserName model.profile model.username_update.username
    in
      ({ model | profile = profile }, put_profile model.flags.csrftoken profile)

  CancelUsernameUpdate ->
    (toggle_username_update model, Cmd.none)

  Submitted (Ok student_profile) ->
    ({ model | profile = student_profile, editing = Dict.fromList [] }, Cmd.none)

  Submitted (Err err) -> let _ = Debug.log "submitted error" err in
    case err of
      Http.BadStatus resp ->
        case (Json.Decode.decodeString (Json.Decode.dict Json.Decode.string) resp.body) of
          Ok errors ->
            ({ model | errors = errors }, Cmd.none)
          _ ->
            (model, Cmd.none)

      Http.BadPayload err resp ->
        (model, Cmd.none)

      _ ->
        (model, Cmd.none)

  CloseHelp help_msg ->
    ({ model | help = (Student.Profile.Help.set_visible help_msg False model.help) }, Cmd.none)

  Logout msg ->
    (model, Student.Profile.logout model.profile model.flags.csrftoken LoggedOut)

  LoggedOut (Ok logout_resp) ->
    (model, Ports.redirect logout_resp.redirect)

  LoggedOut (Err err) -> let _ = Debug.log "log out error" err in
    (model, Cmd.none)
