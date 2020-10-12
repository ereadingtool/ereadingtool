module User.Student.Profile exposing
    ( StudentProfile(..)
    , StudentProfileParams
    , StudentURIParams
    , StudentURIs(..)
    , decoder
    , initProfile
    , performanceReport
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

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (hardcoded, required)
import Task exposing (perform)
import Text.Model as Text
import User.Student.Performance.Report exposing (PerformanceReport)
import User.Student.Resource as StudentResource
import Utils


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
    = StudentProfile (Maybe Int) (Maybe StudentResource.StudentUsername) StudentResource.StudentEmail (Maybe Text.TextDifficulty) (List Text.TextDifficulty) StudentURIs PerformanceReport


studentDifficultyPreference : StudentProfile -> Maybe Text.TextDifficulty
studentDifficultyPreference (StudentProfile _ _ _ diff_pref _ _ _) =
    diff_pref


setStudentDifficultyPreference : StudentProfile -> Text.TextDifficulty -> StudentProfile
setStudentDifficultyPreference (StudentProfile id username email _ diffs logout_uri perfReport) preference =
    StudentProfile id username email (Just preference) diffs logout_uri perfReport


setUserName : StudentProfile -> StudentResource.StudentUsername -> StudentProfile
setUserName (StudentProfile id _ email diff_pref diffs logout_uri perfReport) new_username =
    StudentProfile id (Just new_username) email diff_pref diffs logout_uri perfReport


studentID : StudentProfile -> Maybe Int
studentID (StudentProfile id _ _ _ _ _ _) =
    id


studentDifficulties : StudentProfile -> List Text.TextDifficulty
studentDifficulties (StudentProfile _ _ _ _ diffs _ _) =
    diffs


studentUserName : StudentProfile -> Maybe StudentResource.StudentUsername
studentUserName (StudentProfile _ username _ _ _ _ _) =
    username


studentUserNameToString : StudentResource.StudentUsername -> String
studentUserNameToString student_username =
    StudentResource.studentUserNameToString student_username


studentEmail : StudentProfile -> StudentResource.StudentEmail
studentEmail (StudentProfile _ _ email _ _ _ _) =
    email


uris : StudentProfile -> StudentURIs
uris (StudentProfile _ _ _ _ _ studentUris _) =
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


performanceReport : StudentProfile -> PerformanceReport
performanceReport (StudentProfile _ _ _ _ _ _ report) =
    report


initProfileUsername : Maybe String -> Maybe StudentResource.StudentUsername
initProfileUsername name =
    name
        |> Maybe.map StudentResource.toStudentUsername


initProfile : StudentProfileParams -> PerformanceReport -> StudentProfile
initProfile params perfReport =
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
        perfReport



-- DECODE


uriParamsDecoder : Decoder StudentURIParams
uriParamsDecoder =
    Decode.succeed StudentURIParams
        |> required "logout_uri" Decode.string
        |> required "profile_uri" Decode.string


performanceReportDecoder : Decoder PerformanceReport
performanceReportDecoder =
    Decode.succeed PerformanceReport
        |> required "html" Decode.string


paramsDecoder : Decoder StudentProfileParams
paramsDecoder =
    Decode.succeed StudentProfileParams
        |> required "id" (Decode.nullable Decode.int)
        |> required "username" (Decode.nullable Decode.string)
        |> required "email" Decode.string
        |> required "difficulty_preference" (Decode.nullable Utils.stringTupleDecoder)
        |> required "difficulties" (Decode.list Utils.stringTupleDecoder)
        |> required "uris" uriParamsDecoder


decoder : Decoder StudentProfile
decoder =
    Decode.map2 initProfile
        (Decode.field "profile" paramsDecoder)
        (Decode.field "performance_report" performanceReportDecoder)
