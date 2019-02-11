module User.Profile exposing (..)

import Profile exposing (..)

import Config exposing (student_api_endpoint)

import Html exposing (Html, div)

import Http exposing (..)

import Instructor.Profile exposing (InstructorProfile, InstructorProfileParams)
import Instructor.View

import Student.Profile
import Student.Profile.Decode

import Student.View

import Text.Translations.Decode exposing (TextWord, Flashcards)

import Menu.Msg exposing (Msg)

import Menu.Logout

type Profile = Student Student.Profile.StudentProfile | Instructor InstructorProfile | EmptyProfile

fromStudentProfile : Student.Profile.StudentProfile -> Profile
fromStudentProfile student_profile = Student student_profile

fromInstructorProfile : InstructorProfile -> Profile
fromInstructorProfile instructor_profile = Instructor instructor_profile

init_profile:
 { a | instructor_profile : Maybe InstructorProfileParams, student_profile : Maybe Student.Profile.StudentProfileParams }
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

view_profile_menu_items : Profile -> (Msg -> msg) -> Maybe (List (Html msg))
view_profile_menu_items profile top_level_msg =
  case profile of
    (Instructor instructor_profile) ->
      Just (Instructor.View.view_instructor_profile_menu_items instructor_profile top_level_msg)

    (Student student_profile) ->
      Just (Student.View.view_student_profile_menu_items student_profile top_level_msg)

    EmptyProfile ->
      Nothing

retrieve_student_profile : (Result Error Student.Profile.StudentProfile -> msg) -> ProfileID -> Cmd msg
retrieve_student_profile msg profile_id =
  let
    request =
      Http.get
        (String.join "" [student_api_endpoint, (toString profile_id) ++ "/"])
        Student.Profile.Decode.studentProfileDecoder
  in
    Http.send msg request

logout : Profile -> String -> (Result Http.Error Menu.Logout.LogOutResp -> msg) -> Cmd msg
logout profile csrftoken logout_msg =
  case profile of
    Student student_profile ->
      Student.Profile.logout student_profile csrftoken logout_msg

    Instructor instructor_profile ->
      Instructor.Profile.logout instructor_profile csrftoken logout_msg

    EmptyProfile ->
      Cmd.none


flashcards : Profile -> Maybe Flashcards
flashcards profile =
  case profile of
    Student profile ->
      Student.Profile.studentFlashcards profile

    _ ->
      Nothing

addFlashcard : Profile -> TextWord -> Profile
addFlashcard profile text_word =
  case profile of
    Student profile ->
      fromStudentProfile (Student.Profile.addFlashcard profile text_word)

    _ ->
      profile

removeFlashcard : Profile -> TextWord -> Profile
removeFlashcard profile text_word =
  case profile of
    Student profile ->
      fromStudentProfile (Student.Profile.removeFlashcard profile text_word)

    _ ->
      profile
