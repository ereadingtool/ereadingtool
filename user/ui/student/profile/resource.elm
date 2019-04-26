module Student.Profile.Resource exposing (..)

import Student.Profile
import Student.Resource

import Student.Profile.Decode
import Student.Profile.Encode

import HttpHelpers
import Http

import Flags

import Menu.Logout

import Student.Profile.Msg exposing (Msg(..))


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

updateProfile : Flags.CSRFToken -> Student.Resource.StudentEndpointURI -> Student.Profile.StudentProfile -> Cmd Msg
updateProfile csrftoken student_endpoint_uri student_profile =
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
  -> Student.Resource.StudentResearchConsentURI
  -> Student.Profile.StudentProfile
  -> Bool
  -> Cmd Msg
toggleResearchConsent csrftoken consent_method_uri student_profile consent =
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

logout :
     Student.Profile.StudentProfile
  -> Flags.CSRFToken
  -> (Result Http.Error Menu.Logout.LogOutResp -> msg)
  -> Cmd msg
logout student_profile csrftoken logout_msg =
  let
    request =
      HttpHelpers.post_with_headers
        (Student.Resource.uriToString
          (Student.Resource.studentLogoutURI (Student.Profile.studentLogoutURI student_profile)))
        [Http.header "X-CSRFToken" csrftoken] Http.emptyBody Menu.Logout.logoutRespDecoder
  in
    Http.send logout_msg request
