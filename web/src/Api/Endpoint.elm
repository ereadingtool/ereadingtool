module Api.Endpoint exposing
    ( Endpoint
    , ForgotPasswordEndpoint
    , InstructorInviteEndpoint
    , InstructorLogoutEndpoint
    , ResetPasswordConfirmEndpoint
    , StudentEndpoint
    , StudentResearchConsentEndpoint
    , StudentUsernameValidEndpoint
    , forgotPasswordEndpoint
    , instructorInviteEndpoint
    , instructorLogoutEndpoint
    , passwordResetConfirmEndpoint
    , request
    , studentLogoutEndpoint
    , studentResearchConsentEndpoint
    , studentValidUsernameEndpoint
    )

import Api.Config
import Http
import Profile
import Url.Builder exposing (QueryParameter)


type Endpoint a
    = Endpoint a String (List String) (Maybe (List QueryParameter))


unwrap : Endpoint a -> String
unwrap (Endpoint _ baseUrl paths queryParams) =
    Url.Builder.crossOrigin baseUrl paths (Maybe.withDefault [] queryParams)



-- REQUESTS


request :
    { method : String
    , headers : List Http.Header
    , url : Endpoint a
    , body : Http.Body
    , expect : Http.Expect msg
    , timeout : Maybe Float
    , tracker : Maybe String
    }
    -> Cmd msg
request config =
    Http.request
        { method = config.method
        , headers = config.headers
        , url = unwrap config.url
        , body = config.body
        , expect = config.expect
        , timeout = config.timeout
        , tracker = config.tracker
        }



-- ENDPOINTS


type StudentEndpoint
    = StudentEndpoint


type StudentLogoutEndpoint
    = StudentLogoutEndpoint


type StudentResearchConsentEndpoint
    = StudentResearchConsentEndpoint


type StudentUsernameValidEndpoint
    = StudentUsernameValidEndpoint


type InstructorLogoutEndpoint
    = InstructorLogoutEndpoint


type InstructorInviteEndpoint
    = InstructorInviteEndpoint


type ForgotPasswordEndpoint
    = ForgotPasswordEndpoint


type ResetPasswordConfirmEndpoint
    = ResetPasswordConfirmEndpoint


studentValidUsernameEndpoint : Api.Config.Config -> Endpoint StudentUsernameValidEndpoint
studentValidUsernameEndpoint config =
    Endpoint
        StudentUsernameValidEndpoint
        (Api.Config.restApiUrl config)
        [ "api", "username" ]
        Nothing


studentEndpoint : Profile.ProfileID -> Api.Config.Config -> Endpoint StudentEndpoint
studentEndpoint profileId config =
    Endpoint
        StudentEndpoint
        (Api.Config.restApiUrl config)
        [ "api", "student", String.fromInt (Profile.profileID profileId) ]
        Nothing


studentResearchConsentEndpoint : Profile.ProfileID -> Api.Config.Config -> Endpoint StudentResearchConsentEndpoint
studentResearchConsentEndpoint profileId config =
    Endpoint
        StudentResearchConsentEndpoint
        (Api.Config.restApiUrl config)
        [ "api", "student", String.fromInt (Profile.profileID profileId), "consent_to_research" ]
        Nothing


studentLogoutEndpoint : Api.Config.Config -> Endpoint StudentLogoutEndpoint
studentLogoutEndpoint config =
    Endpoint
        StudentLogoutEndpoint
        (Api.Config.restApiUrl config)
        [ "api", "student", "logout" ]
        Nothing


instructorLogoutEndpoint : Api.Config.Config -> Endpoint InstructorLogoutEndpoint
instructorLogoutEndpoint config =
    Endpoint
        InstructorLogoutEndpoint
        (Api.Config.restApiUrl config)
        [ "api", "instructor", "logout" ]
        Nothing


instructorInviteEndpoint : Api.Config.Config -> Endpoint InstructorInviteEndpoint
instructorInviteEndpoint config =
    Endpoint
        InstructorInviteEndpoint
        (Api.Config.restApiUrl config)
        [ "api", "instructor", "invite" ]
        Nothing


forgotPasswordEndpoint : Api.Config.Config -> Endpoint ForgotPasswordEndpoint
forgotPasswordEndpoint config =
    Endpoint
        ForgotPasswordEndpoint
        (Api.Config.restApiUrl config)
        [ "api", "password", "reset" ]
        Nothing


passwordResetConfirmEndpoint : Api.Config.Config -> Endpoint ResetPasswordConfirmEndpoint
passwordResetConfirmEndpoint config =
    Endpoint
        ResetPasswordConfirmEndpoint
        (Api.Config.restApiUrl config)
        [ "api", "password", "reset", "confirm" ]
        Nothing
