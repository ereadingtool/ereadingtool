module Profile exposing (..)

import Config exposing (student_api_endpoint)

import Html exposing (Html, div)

import Http exposing (..)

import Instructor.Profile exposing (InstructorProfile, InstructorProfileParams)
import Instructor.View

import Student.Profile.Model exposing (StudentProfile, StudentProfileParams, studentProfileDecoder)
import Student.View

import Menu.Msg exposing (Msg)

import Menu.Logout

type alias ProfileID = Int
type alias ProfileType = String

type Profile = Student StudentProfile | Instructor InstructorProfile | EmptyProfile

fromStudentProfile : StudentProfile -> Profile
fromStudentProfile student_profile = Student student_profile

fromInstructorProfile : InstructorProfile -> Profile
fromInstructorProfile instructor_profile = Instructor instructor_profile

init_profile:
 { a | instructor_profile : Maybe InstructorProfileParams, student_profile : Maybe StudentProfileParams }
    -> Profile
init_profile flags =
  case flags.instructor_profile of
    Just instructor_profile_params ->
      Instructor (Instructor.Profile.init_profile instructor_profile_params)

    Nothing ->
      case flags.student_profile of
        Just student_profile_params ->
          Student (Student.Profile.Model.init_profile student_profile_params)

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

retrieve_student_profile : (Result Error StudentProfile -> msg) -> ProfileID -> Cmd msg
retrieve_student_profile msg profile_id =
  let
    request = Http.get (String.join "" [student_api_endpoint, (toString profile_id) ++ "/"]) studentProfileDecoder
  in
    Http.send msg request

logout : Profile -> String -> (Result Http.Error Menu.Logout.LogOutResp -> msg) -> Cmd msg
logout profile csrftoken logout_msg =
  case profile of
    Student student_profile ->
      Student.Profile.Model.logout student_profile csrftoken logout_msg

    Instructor instructor_profile ->
      Instructor.Profile.logout instructor_profile csrftoken logout_msg

    EmptyProfile ->
      Cmd.none
