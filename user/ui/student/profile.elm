module Student.Profile exposing (..)

import Dict exposing (Dict)

import Text.Model as Text

import Config exposing (student_api_endpoint, student_logout_api_endpoint)

import Text.Translations exposing (Phrase, Grammemes)
import Text.Translations.Decode exposing (TextWord, Flashcards)

import TextReader.TextWord

import HttpHelpers
import Http

import Menu.Logout

type alias PerformanceReport = {html: String, pdf_link: String}


emptyPerformanceReport : PerformanceReport
emptyPerformanceReport =
  {html="<div>No results found.</div>", pdf_link=""}

type alias StudentProfileParams = {
    id: Maybe Int
  , username: String
  , email: String
  , difficulty_preference: Maybe Text.TextDifficulty
  , difficulties: List Text.TextDifficulty
  }

type StudentProfile =
  StudentProfile StudentProfileParams (Maybe PerformanceReport) (Maybe Text.Translations.Decode.Flashcards)


emptyStudentProfile : StudentProfile
emptyStudentProfile = StudentProfile {
    id = Nothing
  , username = ""
  , email = ""
  , difficulty_preference = Nothing
  , difficulties = [] } Nothing Nothing


studentDifficultyPreference : StudentProfile -> Maybe Text.TextDifficulty
studentDifficultyPreference (StudentProfile attrs _ _) = attrs.difficulty_preference

setStudentDifficultyPreference : StudentProfile -> Text.TextDifficulty -> StudentProfile
setStudentDifficultyPreference (StudentProfile attrs report flashcards) preference =
  StudentProfile { attrs | difficulty_preference = Just preference } report flashcards

setUserName : StudentProfile -> String -> StudentProfile
setUserName (StudentProfile attrs report flashcards) new_username =
  StudentProfile { attrs | username = new_username } report flashcards

studentID : StudentProfile -> Maybe Int
studentID (StudentProfile attrs _ _) = attrs.id

studentUpdateURI : Int -> String
studentUpdateURI id =
  String.join "" [student_api_endpoint, toString id, "/"]

studentDifficulties : StudentProfile -> List Text.TextDifficulty
studentDifficulties (StudentProfile attrs _ _) = attrs.difficulties

studentUserName : StudentProfile -> String
studentUserName (StudentProfile attrs _ _) = attrs.username

studentEmail : StudentProfile -> String
studentEmail (StudentProfile attrs _ _) = attrs.email

studentPerformanceReport : StudentProfile -> PerformanceReport
studentPerformanceReport (StudentProfile _ performance_report _ ) =
  Maybe.withDefault emptyPerformanceReport performance_report

studentFlashcards : StudentProfile -> Maybe Flashcards
studentFlashcards (StudentProfile attrs report flashcards) = flashcards

addFlashcard : StudentProfile -> TextReader.TextWord.TextWord -> StudentProfile
addFlashcard (StudentProfile attrs report flashcards) text_word =
  let
    phrase = TextReader.TextWord.phrase text_word
  in
    StudentProfile attrs report (Just <| Dict.insert phrase text_word (Maybe.withDefault Dict.empty flashcards))

removeFlashcard : StudentProfile -> TextReader.TextWord.TextWord -> StudentProfile
removeFlashcard (StudentProfile attrs report flashcards) text_word =
  let
    phrase = TextReader.TextWord.phrase text_word
    new_flashcards = Just <| Dict.remove phrase (Maybe.withDefault Dict.empty flashcards)
  in
    StudentProfile attrs report new_flashcards

init_profile :
     StudentProfileParams
  -> Maybe PerformanceReport
  -> Maybe (List (Phrase, TextReader.TextWord.TextWordParams)) -> StudentProfile
init_profile params performance_report flashcards =
  let
    new_flashcards =
      (case flashcards of
        Just fcards ->
             Dict.fromList
          <| List.map (\(phrase, text_word) -> (phrase, TextReader.TextWord.newFromParams text_word)) fcards

        Nothing ->
          Dict.empty)
  in
    StudentProfile params performance_report (Just new_flashcards)

logout : StudentProfile -> String -> (Result Http.Error Menu.Logout.LogOutResp -> msg) -> Cmd msg
logout student_profile csrftoken logout_msg =
  let
    request =
      HttpHelpers.post_with_headers
        Config.student_logout_api_endpoint
        [Http.header "X-CSRFToken" csrftoken] Http.emptyBody Menu.Logout.logoutRespDecoder
  in
    Http.send logout_msg request
