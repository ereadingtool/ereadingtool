module Profile exposing (StudentProfile, studentProfile, studentDifficultyPreference, emptyStudentProfile,
  studentDifficulties, studentProfileDecoder, studentUserName, view_student_profile_header, retrieve_student_profile
  , view_instructor_profile_header, view_profile_header, InstructorProfile, init_profile, ProfileID, ProfileType
  , StudentProfileParams, InstructorProfileParams, Profile)

import Model
import Config exposing (student_api_endpoint)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)
import Html exposing (Html, div)

import Http exposing (..)

import Html.Attributes exposing (classList, attribute)

type alias ProfileID = Int
type alias ProfileType = String

type alias StudentProfileParams = {
    id: Maybe Int
  , username: String
  , difficulty_preference: Maybe Model.TextDifficulty
  , difficulties: List Model.TextDifficulty }

type alias InstructorProfileParams = { id: Maybe Int, username: String }

type StudentProfile = StudentProfile StudentProfileParams

type InstructorProfile = InstructorProfile InstructorProfileParams

type Profile = Student StudentProfile | Instructor InstructorProfile | EmptyProfile

studentProfile : StudentProfileParams -> StudentProfile
studentProfile params = StudentProfile params

studentDifficultyPreference : StudentProfile -> Maybe Model.TextDifficulty
studentDifficultyPreference (StudentProfile attrs) = attrs.difficulty_preference

studentDifficulties : StudentProfile -> List Model.TextDifficulty
studentDifficulties (StudentProfile attrs) = attrs.difficulties

studentUserName : StudentProfile -> String
studentUserName (StudentProfile attrs) = attrs.username

view_student_profile_header : StudentProfile -> List (Html msg)
view_student_profile_header (StudentProfile attrs) = [
    Html.div [] [ Html.text "Logged in as:" ], Html.a [attribute "href" "/profile/student/"] [ Html.text attrs.username ]
  ]

view_instructor_profile_header : InstructorProfile -> List (Html msg)
view_instructor_profile_header (InstructorProfile attrs) = [
    Html.div [] [ Html.text "Logged in as:" ], Html.a [attribute "href" "/profile/instructor/"] [ Html.text attrs.username ]
  ]

init_profile:
 { a | instructor_profile : Maybe InstructorProfileParams, profile_type : String, student_profile : Maybe StudentProfileParams }
    -> Profile
init_profile flags =
  case flags.profile_type of
        "student" -> case flags.student_profile of
          Just params -> Student (StudentProfile params)
          _ -> EmptyProfile
        "instructor" -> case flags.instructor_profile of
          Just params -> Instructor (InstructorProfile params)
          _ -> EmptyProfile
        _ -> EmptyProfile

view_profile_header : Profile -> Maybe (List (Html msg))
view_profile_header profile =
  case profile of
    (Instructor instructor_profile) -> Just (view_instructor_profile_header instructor_profile)
    (Student student_profile) -> Just (view_student_profile_header student_profile)
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
