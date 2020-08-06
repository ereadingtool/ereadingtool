module Api.Endpoint exposing
    ( Endpoint
    , forgotPassword
    , instructorSignup
    , request
    , studentSignup
    , test
    )

import Http
import Url.Builder exposing (QueryParameter)


type Endpoint
    = Endpoint String


unwrap : Endpoint -> String
unwrap (Endpoint val) =
    val


url : String -> List String -> List QueryParameter -> Endpoint
url baseUrl paths queryParams =
    Url.Builder.crossOrigin baseUrl
        paths
        queryParams
        |> Endpoint



-- REQUESTS


request :
    { method : String
    , headers : List Http.Header
    , url : Endpoint
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


test : String -> Endpoint
test baseUrl =
    url baseUrl [ "test" ] []


forgotPassword : String -> Endpoint
forgotPassword baseUrl =
    url baseUrl [ "password", "reset" ] []


instructorSignup : String -> Endpoint
instructorSignup baseUrl =
    url baseUrl [ "instructor", "signup" ] []


studentSignup : String -> Endpoint
studentSignup baseUrl =
    url baseUrl [ "student", "signup" ] []
