module Student.Profile exposing
    ( StudentProfile
    , StudentProfileParams
    , StudentURIParams
    , initProfile
    , profileUriToString
    , setStudentDifficultyPreference
    , setUserName
    , studentDifficulties
    , studentDifficultyPreference
    , studentEmail
    , studentID
    , studentLogoutURI
    , studentUserName
    , studentUserNameToString
    )

import Student.Resource
import Text.Model as Text


type alias StudentURIParams =
    { logout_uri : String
    , profile_uri : String
    }


type alias StudentProfileParams =
    { id : Maybe Int
    , username : Maybe String
    , email : String
    , difficulty_preference : Maybe Text.TextDifficulty
    , difficulties : List Text.TextDifficulty
    , uris : StudentURIParams
    }


type StudentURIs
    = StudentURIs Student.Resource.StudentLogoutURI Student.Resource.StudentProfileURI


type StudentProfile
    = StudentProfile (Maybe Int) (Maybe Student.Resource.StudentUsername) Student.Resource.StudentEmail (Maybe Text.TextDifficulty) (List Text.TextDifficulty) StudentURIs


studentDifficultyPreference : StudentProfile -> Maybe Text.TextDifficulty
studentDifficultyPreference (StudentProfile _ _ _ diff_pref _ _) =
    diff_pref


setStudentDifficultyPreference : StudentProfile -> Text.TextDifficulty -> StudentProfile
setStudentDifficultyPreference (StudentProfile id username email _ diffs logout_uri) preference =
    StudentProfile id username email (Just preference) diffs logout_uri


setUserName : StudentProfile -> Student.Resource.StudentUsername -> StudentProfile
setUserName (StudentProfile id _ email diff_pref diffs logout_uri) new_username =
    StudentProfile id (Just new_username) email diff_pref diffs logout_uri


studentID : StudentProfile -> Maybe Int
studentID (StudentProfile id _ _ _ _ _) =
    id


studentDifficulties : StudentProfile -> List Text.TextDifficulty
studentDifficulties (StudentProfile _ _ _ _ diffs _) =
    diffs


studentUserName : StudentProfile -> Maybe Student.Resource.StudentUsername
studentUserName (StudentProfile _ username _ _ _ _) =
    username


studentUserNameToString : Student.Resource.StudentUsername -> String
studentUserNameToString student_username =
    Student.Resource.studentUserNameToString student_username


studentEmail : StudentProfile -> Student.Resource.StudentEmail
studentEmail (StudentProfile _ _ email _ _ _) =
    email


uris : StudentProfile -> StudentURIs
uris (StudentProfile _ _ _ _ _ studentUris) =
    studentUris


logoutURI : StudentURIs -> Student.Resource.StudentLogoutURI
logoutURI (StudentURIs logout _) =
    logout


profileURI : StudentURIs -> Student.Resource.StudentProfileURI
profileURI (StudentURIs _ profile) =
    profile


profileUriToString : StudentProfile -> String
profileUriToString student_profile =
    Student.Resource.uriToString (Student.Resource.studentProfileURI (profileURI (uris student_profile)))


studentLogoutURI : StudentProfile -> Student.Resource.StudentLogoutURI
studentLogoutURI student_profile =
    logoutURI (uris student_profile)


initProfileUsername : Maybe String -> Maybe Student.Resource.StudentUsername
initProfileUsername name =
    name
        |> Maybe.map Student.Resource.toStudentUsername


initProfile : StudentProfileParams -> StudentProfile
initProfile params =
    StudentProfile
        params.id
        (initProfileUsername params.username)
        (Student.Resource.toStudentEmail params.email)
        params.difficulty_preference
        params.difficulties
        (StudentURIs
            (Student.Resource.toStudentLogoutURI params.uris.logout_uri)
            (Student.Resource.toStudentProfileURI params.uris.profile_uri)
        )
