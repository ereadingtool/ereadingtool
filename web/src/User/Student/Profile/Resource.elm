module User.Student.Profile.Resource exposing
    ( logout
    , toggleResearchConsent
    , updateProfile
    , validateUsername
    )

import Flags
import Http
import Menu.Logout
import User.Student.Profile as StudentProfile
import User.Student.Profile.Decode as StudentProfileDecode
import User.Student.Profile.Encode as StudentProfileEncode
import User.Student.Profile.Msg exposing (Msg(..))
import User.Student.Resource as StudentResource


validateUsername : Flags.CSRFToken -> StudentResource.StudentUsernameValidURI -> String -> Cmd Msg
validateUsername csrftoken username_valid_uri username =
    let
        req =
            HttpHelpers.post_with_headers
                (StudentResource.uriToString (StudentResource.studentUsernameValidURI username_valid_uri))
                [ Http.header "X-CSRFToken" csrftoken ]
                (Http.jsonBody (StudentProfileEncode.username_valid_encode username))
                StudentProfileDecode.username_valid_decoder
    in
    Http.send ValidUsername req


updateProfile : Flags.CSRFToken -> StudentResource.StudentEndpointURI -> StudentProfile.StudentProfile -> Cmd Msg
updateProfile csrftoken student_endpoint_uri student_profile =
    case StudentProfile.studentID student_profile of
        Just _ ->
            let
                encoded_profile =
                    StudentProfileEncode.profileEncoder student_profile

                req =
                    HttpHelpers.put_with_headers
                        (StudentResource.uriToString (StudentResource.studentEndpointURI student_endpoint_uri))
                        [ Http.header "X-CSRFToken" csrftoken ]
                        (Http.jsonBody encoded_profile)
                        StudentProfileDecode.studentProfileDecoder
            in
            Http.send Submitted req

        Nothing ->
            Cmd.none


toggleResearchConsent :
    Flags.CSRFToken
    -> StudentResource.StudentResearchConsentURI
    -> StudentProfile.StudentProfile
    -> Bool
    -> Cmd Msg
toggleResearchConsent csrftoken consent_method_uri student_profile consent =
    case StudentProfile.studentID student_profile of
        Just _ ->
            let
                encoded_consent =
                    StudentProfileEncode.consentEncoder consent

                req =
                    HttpHelpers.put_with_headers
                        (StudentResource.uriToString (StudentResource.studentConsentURI consent_method_uri))
                        [ Http.header "X-CSRFToken" csrftoken ]
                        (Http.jsonBody encoded_consent)
                        StudentProfileDecode.studentConsentRespDecoder
            in
            Http.send SubmittedConsent req

        Nothing ->
            Cmd.none


logout :
    StudentProfile.StudentProfile
    -> Flags.CSRFToken
    -> (Result Http.Error Menu.Logout.LogOutResp -> msg)
    -> Cmd msg
logout student_profile csrftoken logout_msg =
    let
        request =
            HttpHelpers.post_with_headers
                (StudentResource.uriToString
                    (StudentResource.studentLogoutURI (StudentProfile.studentLogoutURI student_profile))
                )
                [ Http.header "X-CSRFToken" csrftoken ]
                Http.emptyBody
                Menu.Logout.logoutRespDecoder
    in
    Http.send logout_msg request
