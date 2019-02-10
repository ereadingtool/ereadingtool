module Student.Profile exposing (..)

import Dict exposing (Dict)

import Text.Model as Text

import Config exposing (student_api_endpoint, student_logout_api_endpoint)

import Text.Translations exposing (Word, Grammemes)
import Text.Translations.Decode exposing (TextWord, Flashcards)

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
  , performance_report: PerformanceReport
  , flashcards: Maybe (List (Word, Text.Translations.Decode.TextWord))
  }

type StudentProfile = StudentProfile StudentProfileParams (Maybe Text.Translations.Decode.Flashcards)


emptyStudentProfile : StudentProfile
emptyStudentProfile = StudentProfile {
    id = Nothing
  , username = ""
  , email = ""
  , difficulty_preference = Nothing
  , difficulties = []
  , performance_report = emptyPerformanceReport
  , flashcards = Nothing } Nothing


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
  StudentProfile attrs (Just <| Dict.insert text_word.word text_word (Maybe.withDefault Dict.empty flashcards))

removeFlashcard : StudentProfile -> TextWord -> StudentProfile
removeFlashcard (StudentProfile attrs flashcards) text_word =
  let
    new_flashcards = Just <| Dict.remove text_word.word (Maybe.withDefault Dict.empty flashcards)
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
