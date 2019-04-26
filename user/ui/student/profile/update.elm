module Student.Profile.Update exposing (..)

import Http exposing (..)

import Json.Decode

import Dict exposing (Dict)

import Student.Profile.Msg exposing (..)

import Student.Profile.Model exposing (Model)
import Student.Profile.Help

import Student.Profile exposing (StudentProfileParams)

import Student.Profile.Resource

import Ports


toggleUsernameUpdate : Model -> Model
toggleUsernameUpdate model =
  { model | editing =
      (if Dict.member "username" model.editing then
        Dict.remove "username" model.editing
       else Dict.insert "username" True model.editing) }

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
    validateUsername =
      Student.Profile.Resource.validateUsername
        model.flags.csrftoken model.student_endpoints.student_username_validation_uri

    updateProfile =
      Student.Profile.Resource.updateProfile model.flags.csrftoken model.student_endpoints.student_endpoint_uri

    toggleResearchConsent =
      Student.Profile.Resource.toggleResearchConsent
        model.flags.csrftoken model.student_endpoints.student_endpoint_uri model.profile
  in
    case msg of
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
          ( { model | username_update = new_username_update }, validateUsername value)

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
          (model, updateProfile new_student_profile)

      ToggleUsernameUpdate ->
        (toggleUsernameUpdate model, Cmd.none)

      ToggleResearchConsent ->
        ( model, toggleResearchConsent (not model.consenting_to_research))

      SubmitUsernameUpdate ->
        let
          profile = Student.Profile.setUserName model.profile model.username_update.username
        in
          ( { model | profile = profile }, updateProfile profile)

      CancelUsernameUpdate ->
        (toggleUsernameUpdate model, Cmd.none)

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

      SubmittedConsent (Ok resp) ->
        (model, Cmd.none)

      SubmittedConsent (Err err) -> let _ = Debug.log "submitted error" err in
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
        ({ model | help = (Student.Profile.Help.setVisible model.help help_msg False) }, Cmd.none)

      PrevHelp ->
        ({ model | help = (Student.Profile.Help.prev model.help) }, Student.Profile.Help.scrollToPrevMsg model.help)

      NextHelp ->
        ({ model | help = (Student.Profile.Help.next model.help) }, Student.Profile.Help.scrollToNextMsg model.help)

      Logout msg ->
        (model, Student.Profile.Resource.logout model.profile model.flags.csrftoken LoggedOut)

      LoggedOut (Ok logout_resp) ->
        (model, Ports.redirect logout_resp.redirect)

      LoggedOut (Err err) -> let _ = Debug.log "log out error" err in
        (model, Cmd.none)
