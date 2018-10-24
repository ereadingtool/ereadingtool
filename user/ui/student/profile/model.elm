module Student.Profile.Model exposing (..)

import Dict exposing (Dict)

import Text.Model as Text
import Text.Reading.Model exposing (TextReading)

import Json.Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

import Config exposing (student_api_endpoint, student_logout_api_endpoint)

import Text.Reading.Model exposing (textReadingsDecoder)

import Text.Definitions exposing (Flashcards, Word, TextWord, Grammemes, textWordDecoder)
import Util exposing (tupleDecoder)

import HttpHelpers
import Http

import Menu.Logout

type alias PerformanceReport = {html: String, pdf_link: String}

emptyPerformanceReport : PerformanceReport
emptyPerformanceReport =
  {html="", pdf_link=""}

type alias StudentProfileParams = {
    id: Maybe Int
  , username: String
  , email: String
  , difficulty_preference: Maybe Text.TextDifficulty
  , difficulties: List Text.TextDifficulty
  , text_reading: Maybe (List TextReading)
  , performance_report: PerformanceReport
  , flashcards: Maybe (List (Word, TextWord))
  }

type StudentProfile = StudentProfile StudentProfileParams (Maybe Flashcards)


emptyStudentProfile : StudentProfile
emptyStudentProfile = StudentProfile {
    id = Nothing
  , username = ""
  , email = ""
  , difficulty_preference = Nothing
  , difficulties = []
  , text_reading = Nothing
  , performance_report = emptyPerformanceReport
  , flashcards = Nothing } Nothing

wordTextWordDecoder : Json.Decode.Decoder ( Word, TextWord )
wordTextWordDecoder =
  Json.Decode.map2 (,) (Json.Decode.index 0 Json.Decode.string) (Json.Decode.index 1 textWordDecoder)

performanceReportDecoder : Json.Decode.Decoder PerformanceReport
performanceReportDecoder =
  decode PerformanceReport
    |> required "html" Json.Decode.string
    |> required "pdf_link" Json.Decode.string

studentProfileParamsDecoder : Json.Decode.Decoder StudentProfileParams
studentProfileParamsDecoder =
  decode StudentProfileParams
    |> required "id" (Json.Decode.nullable Json.Decode.int)
    |> required "username" Json.Decode.string
    |> required "email" Json.Decode.string
    |> required "difficulty_preference" (Json.Decode.nullable tupleDecoder)
    |> required "difficulties" (Json.Decode.list tupleDecoder)
    |> required "text_reading" (Json.Decode.nullable textReadingsDecoder)
    |> required "performance_report" performanceReportDecoder
    |> required "flashcards" (Json.Decode.nullable (Json.Decode.list wordTextWordDecoder))

studentProfileDecoder : Json.Decode.Decoder StudentProfile
studentProfileDecoder =
  Json.Decode.map init_profile studentProfileParamsDecoder

studentDifficultyPreference : StudentProfile -> Maybe Text.TextDifficulty
studentDifficultyPreference (StudentProfile attrs _) = attrs.difficulty_preference

setStudentDifficultyPreference : StudentProfile -> Text.TextDifficulty -> StudentProfile
setStudentDifficultyPreference (StudentProfile attrs flashcards) preference =
  StudentProfile { attrs | difficulty_preference = Just preference } flashcards

setUserName : StudentProfile -> String -> StudentProfile
setUserName (StudentProfile attrs flashcards) new_username =
  StudentProfile { attrs | username = new_username } flashcards

studentID : StudentProfile -> Maybe Int
studentID (StudentProfile attrs _) = attrs.id

studentUpdateURI : Int -> String
studentUpdateURI id =
  String.join "" [student_api_endpoint, toString id, "/"]

studentDifficulties : StudentProfile -> List Text.TextDifficulty
studentDifficulties (StudentProfile attrs _) = attrs.difficulties

studentTextReading : StudentProfile -> Maybe (List TextReading)
studentTextReading (StudentProfile attrs _) = attrs.text_reading

studentUserName : StudentProfile -> String
studentUserName (StudentProfile attrs _) = attrs.username

studentEmail : StudentProfile -> String
studentEmail (StudentProfile attrs _) = attrs.email

studentPerformanceReport : StudentProfile -> PerformanceReport
studentPerformanceReport (StudentProfile attrs _) = attrs.performance_report

studentFlashcards : StudentProfile -> Maybe Flashcards
studentFlashcards (StudentProfile attrs flashcards) = flashcards

addFlashcard : StudentProfile -> TextWord -> StudentProfile
addFlashcard (StudentProfile attrs flashcards) text_word =
  StudentProfile attrs (Just <| Dict.insert text_word.normal_form text_word (Maybe.withDefault Dict.empty flashcards))

removeFlashcard : StudentProfile -> TextWord -> StudentProfile
removeFlashcard (StudentProfile attrs flashcards) text_word =
  let
    new_flashcards = Just <| Dict.remove text_word.normal_form (Maybe.withDefault Dict.empty flashcards)
  in
    StudentProfile attrs new_flashcards

init_profile : StudentProfileParams -> StudentProfile
init_profile params =
  StudentProfile params (Just <| Dict.fromList <| Maybe.withDefault [] params.flashcards)

logout : StudentProfile -> String -> (Result Http.Error Menu.Logout.LogOutResp -> msg) -> Cmd msg
logout student_profile csrftoken logout_msg =
  let
    request =
      HttpHelpers.post_with_headers
        Config.student_logout_api_endpoint
        [Http.header "X-CSRFToken" csrftoken] Http.emptyBody Menu.Logout.logoutRespDecoder
  in
    Http.send logout_msg request
