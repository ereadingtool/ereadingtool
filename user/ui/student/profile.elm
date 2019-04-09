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

type alias StudentProfileParams = {
    id: Maybe Int
  , username: String
  , email: String
  , difficulty_preference: Maybe Text.TextDifficulty
  , difficulties: List Text.TextDifficulty
  }

type StudentProfile =
  StudentProfile (Maybe Int) String String (Maybe Text.TextDifficulty) (List Text.TextDifficulty)

studentDifficultyPreference : StudentProfile -> Maybe Text.TextDifficulty
studentDifficultyPreference (StudentProfile id username email diff_pref diffs) = diff_pref

setStudentDifficultyPreference : StudentProfile -> Text.TextDifficulty -> StudentProfile
setStudentDifficultyPreference (StudentProfile id username email _ diffs) preference =
  StudentProfile id username email (Just preference) diffs

setUserName : StudentProfile -> String -> StudentProfile
setUserName (StudentProfile id _ email diff_pref diffs) new_username =
  StudentProfile id new_username email diff_pref diffs

studentID : StudentProfile -> Maybe Int
studentID (StudentProfile id _ _ _ _) = id

studentUpdateURI : Int -> String
studentUpdateURI id =
  String.join "" [student_api_endpoint, toString id, "/"]

studentDifficulties : StudentProfile -> List Text.TextDifficulty
studentDifficulties (StudentProfile _ _ _ _ diffs) = diffs

studentUserName : StudentProfile -> String
studentUserName (StudentProfile _ username _ _ _) = username

studentEmail : StudentProfile -> String
studentEmail (StudentProfile _ _ email _ _) = email

initProfile : StudentProfileParams -> StudentProfile
initProfile params =
  StudentProfile
    params.id params.username params.email params.difficulty_preference params.difficulties

logout : StudentProfile -> String -> (Result Http.Error Menu.Logout.LogOutResp -> msg) -> Cmd msg
logout student_profile csrftoken logout_msg =
  let
    request =
      HttpHelpers.post_with_headers
        Config.student_logout_api_endpoint
        [Http.header "X-CSRFToken" csrftoken] Http.emptyBody Menu.Logout.logoutRespDecoder
  in
    Http.send logout_msg request
