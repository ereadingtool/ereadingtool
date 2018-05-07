module Profile exposing (StudentProfile, studentProfile, studentDifficultyPreference, emptyStudentProfile,
  studentDifficulties, studentProfileDecoder, studentUserName, view_user_profile_header, update_student_profile)

import Model
import Config exposing (student_api_endpoint)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)
import Html exposing (Html, div)

import Http exposing (..)
import HttpHelpers exposing (post_with_headers)

import Html.Attributes exposing (classList, attribute)

import Flags exposing (ProfileID, ProfileType)

type alias StudentProfileParams = {
    id: Maybe Int
  , username: String
  , difficulty_preference: Maybe Model.TextDifficulty
  , difficulties: List Model.TextDifficulty }

type StudentProfile = StudentProfile StudentProfileParams

studentProfile : StudentProfileParams -> StudentProfile
studentProfile params = StudentProfile params

studentDifficultyPreference : StudentProfile -> Maybe Model.TextDifficulty
studentDifficultyPreference (StudentProfile attrs) = attrs.difficulty_preference

studentDifficulties : StudentProfile -> List Model.TextDifficulty
studentDifficulties (StudentProfile attrs) = attrs.difficulties

studentUserName : StudentProfile -> String
studentUserName (StudentProfile attrs) = attrs.username

view_user_profile_header : StudentProfile -> List (Html msg)
view_user_profile_header (StudentProfile attrs) = [
    Html.div [] [ Html.text "Logged in as:" ], Html.a [attribute "href" "/profile/student/"] [ Html.text attrs.username ],
    Html.div [] [ Html.text "Log out" ]
  ]

emptyStudentProfile : StudentProfile
emptyStudentProfile = StudentProfile {
    id = Nothing
  , username = ""
  , difficulty_preference = Nothing
  , difficulties = [] }

studentProfileParamsDecoder : Decode.Decoder StudentProfileParams
studentProfileParamsDecoder =
  decode StudentProfileParams
    |> required "id" (Decode.nullable Decode.int)
    |> required "username" Decode.string
    |> required "difficulty_preference" (Decode.nullable
      ( Decode.map2 (,) (Decode.index 0 Decode.string) (Decode.index 1 Decode.string) ))
    |> required "difficulties" Model.textDifficultyDecoder


studentProfileDecoder : Decode.Decoder StudentProfile
studentProfileDecoder =
  Decode.map StudentProfile studentProfileParamsDecoder

update_student_profile : (Result Error StudentProfile -> msg) -> ProfileID -> Cmd msg
update_student_profile msg profile_id =  let
    request = Http.get (String.join "" [student_api_endpoint, (toString profile_id) ++ "/"])
      studentProfileDecoder
  in Http.send msg request
