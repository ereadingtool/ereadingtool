module Student.Profile exposing (..)

import Text.Model as Text
import Text.Reading.Model exposing (TextReading)

import Json.Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

import Config exposing (student_api_endpoint, student_logout_api_endpoint)

import Text.Reading.Model exposing (textReadingsDecoder)
import Util exposing (tupleDecoder)

import HttpHelpers
import Http

import Menu.Logout


type alias StudentProfileParams = {
    id: Maybe Int
  , username: String
  , difficulty_preference: Maybe Text.TextDifficulty
  , difficulties: List Text.TextDifficulty
  , text_reading: Maybe (List TextReading) }

type StudentProfile = StudentProfile StudentProfileParams


emptyStudentProfile : StudentProfile
emptyStudentProfile = StudentProfile {
    id = Nothing
  , username = ""
  , difficulty_preference = Nothing
  , difficulties = []
  , text_reading = Nothing }


studentProfileParamsDecoder : Json.Decode.Decoder StudentProfileParams
studentProfileParamsDecoder =
  decode StudentProfileParams
    |> required "id" (Json.Decode.nullable Json.Decode.int)
    |> required "username" Json.Decode.string
    |> required "difficulty_preference" (Json.Decode.nullable tupleDecoder)
    |> required "difficulties" (Json.Decode.list tupleDecoder)
    |> required "text_reading" (Json.Decode.nullable textReadingsDecoder)


studentProfileDecoder : Json.Decode.Decoder StudentProfile
studentProfileDecoder =
  Json.Decode.map StudentProfile studentProfileParamsDecoder

studentDifficultyPreference : StudentProfile -> Maybe Text.TextDifficulty
studentDifficultyPreference (StudentProfile attrs) = attrs.difficulty_preference

setStudentDifficultyPreference : StudentProfile -> Text.TextDifficulty -> StudentProfile
setStudentDifficultyPreference (StudentProfile attrs) preference =
  StudentProfile { attrs | difficulty_preference = Just preference }

studentID : StudentProfile -> Maybe Int
studentID (StudentProfile attrs) = attrs.id

studentUpdateURI : Int -> String
studentUpdateURI id =
  String.join "" [student_api_endpoint, toString id, "/"]

studentDifficulties : StudentProfile -> List Text.TextDifficulty
studentDifficulties (StudentProfile attrs) = attrs.difficulties

studentTextReading : StudentProfile -> Maybe (List TextReading)
studentTextReading (StudentProfile attrs) = attrs.text_reading

studentUserName : StudentProfile -> String
studentUserName (StudentProfile attrs) = attrs.username

init_profile : StudentProfileParams -> StudentProfile
init_profile params = StudentProfile params

logout : StudentProfile -> String -> (Result Http.Error Menu.Logout.LogOutResp -> msg) -> Cmd msg
logout student_profile csrftoken logout_msg =
  let
    request =
      HttpHelpers.post_with_headers
        Config.student_logout_api_endpoint
        [Http.header "X-CSRFToken" csrftoken] Http.emptyBody Menu.Logout.logoutRespDecoder
  in
    Http.send logout_msg request
