module User.Student.Profile.Resource exposing
    ( logout
    , toggleResearchConsent
    , updateProfile
    , validateUsername
    )

import Http
import Api
import Menu.Logout
import User.Student.Profile as StudentProfile
import User.Student.Profile.Decode as StudentProfileDecode
import User.Student.Profile.Encode as StudentProfileEncode
import User.Student.Profile.Msg exposing (Msg(..))
import User.Student.Resource as StudentResource


validateUsername : StudentResource.StudentUsernameValidURI -> String -> Cmd Msg
validateUsername username_valid_uri username =
    Api.post
        (StudentResource.uriToString (StudentResource.studentUsernameValidURI username_valid_uri))
        Nothing
        ValidUsername
        (Http.jsonBody (StudentProfileEncode.username_valid_encode username))
        StudentProfileDecode.username_valid_decoder


updateProfile : StudentResource.StudentEndpointURI -> StudentProfile.StudentProfile -> Cmd Msg
updateProfile student_endpoint_uri student_profile =
    case StudentProfile.studentID student_profile of
        Just _ ->
            Api.put
                (StudentResource.uriToString (StudentResource.studentEndpointURI student_endpoint_uri))
                Nothing
                Submitted
                (Http.jsonBody (StudentProfileEncode.profileEncoder student_profile))
                StudentProfileDecode.studentProfileDecoder

        Nothing ->
            Cmd.none


toggleResearchConsent :
    StudentResource.StudentResearchConsentURI
    -> StudentProfile.StudentProfile
    -> Bool
    -> Cmd Msg
toggleResearchConsent consent_method_uri student_profile consent =
    case StudentProfile.studentID student_profile of
        Just _ ->
            Api.put
                (StudentResource.uriToString (StudentResource.studentConsentURI consent_method_uri))
                Nothing
                SubmittedConsent
                (Http.jsonBody (StudentProfileEncode.consentEncoder consent))
                StudentProfileDecode.studentConsentRespDecoder

        Nothing ->
            Cmd.none


logout :
    StudentProfile.StudentProfile
    -> (Result Http.Error Menu.Logout.LogOutResp -> msg)
    -> Cmd msg
logout student_profile logout_msg =
    Api.post
        (StudentResource.uriToString
            (StudentResource.studentLogoutURI (StudentProfile.studentLogoutURI student_profile))
        )
        Nothing
        logout_msg
        Http.emptyBody
        Menu.Logout.logoutRespDecoder
