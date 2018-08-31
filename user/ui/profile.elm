module Profile exposing (..)

import Config exposing (student_api_endpoint)

import Html exposing (Html, div)

import Http exposing (..)

import Instructor.Profile exposing (InstructorProfile, InstructorProfileParams)
import Instructor.View

import Student.Profile exposing (StudentProfile, StudentProfileParams, studentProfileDecoder)
import Student.View

import Menu.Msg exposing (Msg)

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
          Student (Student.Profile.init_profile student_profile_params)
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
