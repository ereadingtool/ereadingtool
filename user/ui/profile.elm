module Profile exposing (Profile, studentProfile, studentDifficultyPreference, emptyStudentProfile,
  studentDifficulties, studentProfileDecoder, userName)

import Model
import Config exposing (student_api_endpoint)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

import Flags exposing (ProfileID, ProfileType)

type alias StudentProfileParams = {
    id: Maybe Int
  , username: String
  , difficulty_preference: Maybe Model.TextDifficulty
  , difficulties: List Model.TextDifficulty }

type Profile = StudentProfile StudentProfileParams | InstructorProfile

studentProfile : StudentProfileParams -> Profile
studentProfile params = StudentProfile params

studentDifficultyPreference : Profile -> Maybe Model.TextDifficulty
studentDifficultyPreference (StudentProfile attrs) = attrs.difficulty_preference

studentDifficulties : Profile -> List Model.TextDifficulty
studentDifficulties (StudentProfile attrs) = attrs.difficulties

userName : Profile -> String
userName profile = case profile of
  StudentProfile attrs -> attrs.username
  InstructorProfile -> ""

emptyStudentProfile : Profile
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


studentProfileDecoder : Decode.Decoder Profile
studentProfileDecoder =
  Decode.map StudentProfile studentProfileParamsDecoder