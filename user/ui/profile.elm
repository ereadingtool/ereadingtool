module Profile exposing (StudentProfile, studentProfile, studentDifficultyPreference, emptyStudentProfile,
  studentDifficulties, studentProfileDecoder, studentUserName, view_student_profile_header, retrieve_student_profile
  , view_profile_header, init_profile, ProfileID, ProfileType
  , StudentProfileParams, Profile(..), emptyProfile, fromStudentProfile
  , fromInstructorProfile)

import Text.Model as Text
import Config exposing (student_api_endpoint)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)
import Html exposing (Html, div)

import Http exposing (..)

import Html.Attributes exposing (classList, attribute)

import Instructor.Profile exposing (InstructorProfile, InstructorProfileParams)

type alias ProfileID = Int
type alias ProfileType = String

type alias StudentProfileParams = {
    id: Maybe Int
  , username: String
  , difficulty_preference: Maybe Text.TextDifficulty
  , difficulties: List Text.TextDifficulty }

type StudentProfile = StudentProfile StudentProfileParams

type Profile = Student StudentProfile | Instructor InstructorProfile | EmptyProfile

fromStudentProfile : StudentProfile -> Profile
fromStudentProfile student_profile = Student student_profile

fromInstructorProfile : InstructorProfile -> Profile
fromInstructorProfile instructor_profile = Instructor instructor_profile

studentProfile : StudentProfileParams -> StudentProfile
studentProfile params = StudentProfile params

studentDifficultyPreference : StudentProfile -> Maybe Text.TextDifficulty
studentDifficultyPreference (StudentProfile attrs) = attrs.difficulty_preference

studentDifficulties : StudentProfile -> List Text.TextDifficulty
studentDifficulties (StudentProfile attrs) = attrs.difficulties

studentUserName : StudentProfile -> String
studentUserName (StudentProfile attrs) = attrs.username

view_student_profile_header : StudentProfile -> List (Html msg)
view_student_profile_header (StudentProfile attrs) = [
    div [classList [("menu_item", True)]] [
      Html.a [attribute "href" ""] [ Html.text "Flashcards" ]
    ]
  , div [classList [("profile_menu_item", True)]] [
      Html.a [attribute "href" "/profile/student/"] [ Html.text attrs.username ]
    ]
  ]

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
          Student (StudentProfile student_profile_params)
        Nothing ->
          EmptyProfile

emptyProfile : Profile
emptyProfile = EmptyProfile

view_profile_header : Profile -> Maybe (List (Html msg))
view_profile_header profile =
  case profile of
    (Instructor instructor_profile) ->
      Just (Instructor.Profile.view_instructor_profile_header instructor_profile)

    (Student student_profile) ->
      Just (view_student_profile_header student_profile)

    EmptyProfile -> Nothing

emptyStudentProfile : StudentProfile
emptyStudentProfile = StudentProfile {
    id = Nothing
  , username = ""
  , difficulty_preference = Nothing
  , difficulties = [] }

tupleDecoder : Decode.Decoder ( String, String )
tupleDecoder = Decode.map2 (,) (Decode.index 0 Decode.string) (Decode.index 1 Decode.string)

studentProfileParamsDecoder : Decode.Decoder StudentProfileParams
studentProfileParamsDecoder =
  decode StudentProfileParams
    |> required "id" (Decode.nullable Decode.int)
    |> required "username" Decode.string
    |> required "difficulty_preference" (Decode.nullable tupleDecoder)
    |> required "difficulties" (Decode.list tupleDecoder)


studentProfileDecoder : Decode.Decoder StudentProfile
studentProfileDecoder =
  Decode.map StudentProfile studentProfileParamsDecoder

retrieve_student_profile : (Result Error StudentProfile -> msg) -> ProfileID -> Cmd msg
retrieve_student_profile msg profile_id =  let
    request = Http.get (String.join "" [student_api_endpoint, (toString profile_id) ++ "/"])
      studentProfileDecoder
  in Http.send msg request
