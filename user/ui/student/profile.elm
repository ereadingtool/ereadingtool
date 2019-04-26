module Student.Profile exposing (..)

import Text.Model as Text

import Student.Resource


type alias StudentProfileParams = {
    id: Maybe Int
  , username: String
  , email: String
  , difficulty_preference: Maybe Text.TextDifficulty
  , difficulties: List Text.TextDifficulty
  , logout_uri: String
  }

type StudentProfile =
  StudentProfile
    (Maybe Int) String String (Maybe Text.TextDifficulty) (List Text.TextDifficulty) Student.Resource.StudentLogoutURI


studentDifficultyPreference : StudentProfile -> Maybe Text.TextDifficulty
studentDifficultyPreference (StudentProfile id username email diff_pref diffs _) = diff_pref

setStudentDifficultyPreference : StudentProfile -> Text.TextDifficulty -> StudentProfile
setStudentDifficultyPreference (StudentProfile id username email _ diffs logout_uri) preference =
  StudentProfile id username email (Just preference) diffs logout_uri

setUserName : StudentProfile -> String -> StudentProfile
setUserName (StudentProfile id _ email diff_pref diffs logout_uri) new_username =
  StudentProfile id new_username email diff_pref diffs logout_uri

studentID : StudentProfile -> Maybe Int
studentID (StudentProfile id _ _ _ _ _) = id

studentDifficulties : StudentProfile -> List Text.TextDifficulty
studentDifficulties (StudentProfile _ _ _ _ diffs _) = diffs

studentUserName : StudentProfile -> String
studentUserName (StudentProfile _ username _ _ _ _) = username

studentEmail : StudentProfile -> String
studentEmail (StudentProfile _ _ email _ _ _) = email

studentLogoutURI : StudentProfile -> Student.Resource.StudentLogoutURI
studentLogoutURI (StudentProfile _ _ _ _ _ logout_uri) = logout_uri

initProfile : StudentProfileParams -> StudentProfile
initProfile params =
  StudentProfile
    params.id
    params.username
    params.email
    params.difficulty_preference
    params.difficulties
    (Student.Resource.StudentLogoutURI (Student.Resource.URI params.logout_uri))
