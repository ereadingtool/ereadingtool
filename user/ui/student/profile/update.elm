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

import Student.Resource

import Flags

import Ports


validateUsername : Flags.CSRFToken -> Student.Resource.StudentUsernameValidURI -> String -> Cmd Msg
validateUsername csrftoken username_valid_uri username =
  let
    req =
      HttpHelpers.post_with_headers
       (Student.Resource.uriToString (Student.Resource.studentUsernameValidURI username_valid_uri))
       [Http.header "X-CSRFToken" csrftoken]
       (Http.jsonBody (Student.Profile.Encode.username_valid_encode username))
       Student.Profile.Decode.username_valid_decoder
  in
    Http.send ValidUsername req

putProfile : Flags.CSRFToken -> Student.Profile.StudentProfile -> Student.Resource.StudentEndpointURI -> Cmd Msg
putProfile csrftoken student_profile student_endpoint_uri =
  case Student.Profile.studentID student_profile of
    Just id ->
      let
        encoded_profile = Student.Profile.Encode.profileEncoder student_profile
        req =
          HttpHelpers.put_with_headers
           (Student.Resource.uriToString (Student.Resource.studentEndpointURI student_endpoint_uri))
           [Http.header "X-CSRFToken" csrftoken]
           (Http.jsonBody encoded_profile) Student.Profile.Decode.studentProfileDecoder
      in
        Http.send Submitted req

    Nothing ->
      Cmd.none

toggleResearchConsent :
     Flags.CSRFToken
  -> Student.Profile.StudentProfile
  -> Student.Resource.StudentResearchConsentURI
  -> Bool
  -> Cmd Msg
toggleResearchConsent csrftoken student_profile consent_method_uri consent =
  case Student.Profile.studentID student_profile of
    Just id ->
      let
        encoded_consent = Student.Profile.Encode.consentEncoder consent
        req =
          HttpHelpers.put_with_headers
           (Student.Resource.uriToString (Student.Resource.studentConsentURI consent_method_uri))
           [Http.header "X-CSRFToken" csrftoken]
           (Http.jsonBody encoded_consent) Student.Profile.Decode.studentConsentRespDecoder
      in
        Http.send SubmittedConsent req

    Nothing ->
      Cmd.none

toggleUsernameUpdate : Model -> Model
toggleUsernameUpdate model =
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
      ( { model | username_update = new_username_update }
      , validateUsername
          model.flags.csrftoken model.student_endpoints.student_username_validation_uri value)

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
      (model, putProfile model.flags.csrftoken new_student_profile model.student_endpoints.student_endpoint_uri)

  ToggleUsernameUpdate ->
    (toggleUsernameUpdate model, Cmd.none)

  ToggleResearchConsent ->
    ( model
    , toggleResearchConsent
        model.flags.csrftoken
        model.profile
        model.student_endpoints.student_research_consent_uri
        (not model.consenting_to_research))

  SubmitUsernameUpdate ->
    let
      profile = Student.Profile.setUserName model.profile model.username_update.username
    in
      ( { model | profile = profile }
      , putProfile model.flags.csrftoken profile model.student_endpoints.student_endpoint_uri)

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
    (model
    , Student.Profile.logout
        model.profile model.flags.csrftoken LoggedOut)

  LoggedOut (Ok logout_resp) ->
    (model, Ports.redirect logout_resp.redirect)

  LoggedOut (Err err) -> let _ = Debug.log "log out error" err in
    (model, Cmd.none)
