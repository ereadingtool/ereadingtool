module User.Student.Profile exposing
    ( StudentProfile(..)
    , StudentProfileParams
    , StudentURIParams
    , StudentURIs(..)
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

import Text.Model as Text
import User.Student.Resource as StudentResource


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
    = StudentURIs StudentResource.StudentLogoutURI StudentResource.StudentProfileURI


type StudentProfile
    = StudentProfile (Maybe Int) (Maybe StudentResource.StudentUsername) StudentResource.StudentEmail (Maybe Text.TextDifficulty) (List Text.TextDifficulty) StudentURIs


studentDifficultyPreference : StudentProfile -> Maybe Text.TextDifficulty
studentDifficultyPreference (StudentProfile _ _ _ diff_pref _ _) =
    diff_pref


setStudentDifficultyPreference : StudentProfile -> Text.TextDifficulty -> StudentProfile
setStudentDifficultyPreference (StudentProfile id username email _ diffs logout_uri) preference =
    StudentProfile id username email (Just preference) diffs logout_uri


setUserName : StudentProfile -> StudentResource.StudentUsername -> StudentProfile
setUserName (StudentProfile id _ email diff_pref diffs logout_uri) new_username =
    StudentProfile id (Just new_username) email diff_pref diffs logout_uri


studentID : StudentProfile -> Maybe Int
studentID (StudentProfile id _ _ _ _ _) =
    id


studentDifficulties : StudentProfile -> List Text.TextDifficulty
studentDifficulties (StudentProfile _ _ _ _ diffs _) =
    diffs


studentUserName : StudentProfile -> Maybe StudentResource.StudentUsername
studentUserName (StudentProfile _ username _ _ _ _) =
    username


studentUserNameToString : StudentResource.StudentUsername -> String
studentUserNameToString student_username =
    StudentResource.studentUserNameToString student_username


studentEmail : StudentProfile -> StudentResource.StudentEmail
studentEmail (StudentProfile _ _ email _ _ _) =
    email


uris : StudentProfile -> StudentURIs
uris (StudentProfile _ _ _ _ _ studentUris) =
    studentUris


logoutURI : StudentURIs -> StudentResource.StudentLogoutURI
logoutURI (StudentURIs logout _) =
    logout


profileURI : StudentURIs -> StudentResource.StudentProfileURI
profileURI (StudentURIs _ profile) =
    profile


profileUriToString : StudentProfile -> String
profileUriToString student_profile =
    StudentResource.uriToString (StudentResource.studentProfileURI (profileURI (uris student_profile)))


studentLogoutURI : StudentProfile -> StudentResource.StudentLogoutURI
studentLogoutURI student_profile =
    logoutURI (uris student_profile)


initProfileUsername : Maybe String -> Maybe StudentResource.StudentUsername
initProfileUsername name =
    name
        |> Maybe.map StudentResource.toStudentUsername


initProfile : StudentProfileParams -> StudentProfile
initProfile params =
    StudentProfile
        params.id
        (initProfileUsername params.username)
        (StudentResource.toStudentEmail params.email)
        params.difficulty_preference
        params.difficulties
        (StudentURIs
            (StudentResource.toStudentLogoutURI params.uris.logout_uri)
            (StudentResource.toStudentProfileURI params.uris.profile_uri)
        )
