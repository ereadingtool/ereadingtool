module Api.Endpoint exposing (Endpoint, request, StudentEndpoint)

import Http
import Url.Builder exposing (QueryParameter)
import Api.Config
import Profile


type Endpoint a
    = Endpoint a String (List String) (Maybe (List QueryParameter))


unwrap : (Endpoint a) -> String
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


studentEndpoint : Profile.ProfileID -> Api.Config.Config -> Endpoint StudentEndpoint
studentEndpoint profileId config =
    Endpoint
      StudentEndpoint
        (Api.Config.restApiUrl config)
        ["api", "student", String.fromInt (Profile.profileID profileId)]
        Nothing