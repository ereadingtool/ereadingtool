module User.Student.Profile.Resource exposing
    ( logout
    , toggleResearchConsent
    , updateProfile
    , validateUsername
    )

import Api
import Api.Config
import Api.Endpoint exposing (Endpoint, StudentEndpoint, StudentResearchConsentEndpoint, StudentUsernameValidEndpoint)
import Http
import Menu.Logout
import User.Student.Profile as StudentProfile
import User.Student.Profile.Decode as StudentProfileDecode
import User.Student.Profile.Encode as StudentProfileEncode
import User.Student.Profile.Msg exposing (Msg(..))


validateUsername : Endpoint StudentUsernameValidEndpoint -> String -> Cmd Msg
validateUsername username_valid_endpoint username =
    Api.post
        username_valid_endpoint
        Nothing
        (Http.jsonBody (StudentProfileEncode.username_valid_encode username))
        ValidUsername
        StudentProfileDecode.username_valid_decoder


updateProfile : Endpoint StudentEndpoint -> StudentProfile.StudentProfile -> Cmd Msg
updateProfile student_endpoint student_profile =
    case StudentProfile.studentID student_profile of
        Just _ ->
            Api.put
                student_endpoint
                Nothing
                (Http.jsonBody (StudentProfileEncode.profileEncoder student_profile))
                Submitted
                StudentProfileDecode.studentProfileDecoder

        Nothing ->
            Cmd.none


toggleResearchConsent :
    Endpoint StudentResearchConsentEndpoint
    -> Bool
    -> Cmd Msg
toggleResearchConsent consent_method_endpoint consent =
    Api.put
        consent_method_endpoint
        Nothing
        (Http.jsonBody (StudentProfileEncode.consentEncoder consent))
        SubmittedConsent
        StudentProfileDecode.studentConsentRespDecoder


logout :
    Api.Config.Config
    -> (Result Http.Error Menu.Logout.LogOutResp -> msg)
    -> Cmd msg
logout config logout_msg =
    Api.post
        (Api.Endpoint.studentLogoutEndpoint config)
        Nothing
        Http.emptyBody
        logout_msg
        Menu.Logout.logoutRespDecoder
