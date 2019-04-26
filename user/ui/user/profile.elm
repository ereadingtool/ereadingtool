module User.Profile exposing (..)

import Profile exposing (..)
import Flags

import Html exposing (Html, div)

import Http exposing (..)

import Instructor.Profile
import Instructor.View

import Student.Profile
import Student.Resource
import Student.Profile.Decode

import Student.View

import Menu.Msg exposing (Msg)

import Menu.Logout

type Profile =
    Student Student.Profile.StudentProfile
  | Instructor Instructor.Profile.InstructorProfile
  | EmptyProfile

fromStudentProfile : Student.Profile.StudentProfile -> Profile
fromStudentProfile student_profile =
  Student student_profile

fromInstructorProfile : Instructor.Profile.InstructorProfile -> Profile
fromInstructorProfile instructor_profile =
  Instructor instructor_profile

initProfile:
 { a | instructor_profile : Maybe Instructor.Profile.InstructorProfileParams
     , student_profile : Maybe Student.Profile.StudentProfileParams }
    -> Profile
initProfile flags =
  case flags.instructor_profile of
    Just instructor_profile_params ->
      Instructor (Instructor.Profile.initProfile instructor_profile_params)

    Nothing ->
      case flags.student_profile of
        Just student_profile_params ->
          Student (Student.Profile.initProfile student_profile_params)

        Nothing ->
          EmptyProfile

emptyProfile : Profile
emptyProfile = EmptyProfile

view_profile_header : Profile -> (Msg -> msg) -> Maybe (List (Html msg))
view_profile_header profile top_level_msg =
  case profile of
    (Instructor instructor_profile) ->
      Just (Instructor.View.view_instructor_profile_header instructor_profile top_level_msg)

    (Student student_profile) ->
      Just (Student.View.view_student_profile_header student_profile top_level_msg)

    EmptyProfile ->
      Nothing

retrieveStudentProfile :
     (Result Error Student.Profile.StudentProfile -> msg)
  -> ProfileID
  -> Student.Resource.StudentEndpointURI
  -> Cmd msg
retrieveStudentProfile msg profile_id student_endpoint_uri =
  let
    request =
      Http.get
        (Student.Resource.uriToString (Student.Resource.studentEndpointURI student_endpoint_uri))
        Student.Profile.Decode.studentProfileDecoder
  in
    Http.send msg request

logout : Profile -> Flags.CSRFToken -> (Result Http.Error Menu.Logout.LogOutResp -> msg) -> Cmd msg
logout profile csrftoken logout_msg =
  case profile of
    Student student_profile ->
      Student.Profile.logout student_profile csrftoken logout_msg

    Instructor instructor_profile ->
      Instructor.Profile.logout instructor_profile csrftoken logout_msg

    EmptyProfile ->
      Cmd.none
