module Api.Endpoint exposing
    ( Endpoint
    , consentToResearch
    , createText
    , filterToStringQueryParam
    , forgotPassword
    , instructorProfile
    , instructorSignup
    , inviteInstructor
    , request
    , resetPassword
    , studentProfile
    , studentSignup
    , text
    , textLock
    , textSearch
    , validateUsername
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


forgotPassword : String -> Endpoint
forgotPassword baseUrl =
    url baseUrl [ "password", "reset" ] []


resetPassword : String -> Endpoint
resetPassword baseUrl =
    url baseUrl [ "password", "reset", "confirm" ] []


instructorSignup : String -> Endpoint
instructorSignup baseUrl =
    url baseUrl [ "api", "instructor", "signup" ] []


studentSignup : String -> Endpoint
studentSignup baseUrl =
    url baseUrl [ "api", "student", "signup" ] []



-- PROFILE


studentProfile : String -> Int -> Endpoint
studentProfile baseUrl id =
    url baseUrl [ "api", "student", String.fromInt id ++ "/" ] []


instructorProfile : String -> Int -> Endpoint
instructorProfile baseUrl id =
    url baseUrl [ "api", "instructor", String.fromInt id ++ "/" ] []


consentToResearch : String -> Int -> Endpoint
consentToResearch baseUrl id =
    url baseUrl [ "api", "student", String.fromInt id, "consent_to_research" ] []


validateUsername : String -> Endpoint
validateUsername baseUrl =
    url baseUrl [ "api", "username/" ] []



-- TEXT SEARCH


textSearch : String -> List QueryParameter -> Endpoint
textSearch baseUrl queryParameters =
    url baseUrl [ "api", "text/" ] queryParameters



-- TEXT CREATE AND EDIT


createText : String -> Endpoint
createText baseUrl =
    url baseUrl [ "api", "text/" ] []


text : String -> Int -> Maybe (List QueryParameter) -> Endpoint
text baseUrl id maybeQueryParameters =
    case maybeQueryParameters of
        Just queryParameters ->
            url baseUrl [ "api", "text", String.fromInt id ++ "/" ] queryParameters

        Nothing ->
            url baseUrl [ "api", "text", String.fromInt id ++ "/" ] []


textLock : String -> Int -> Endpoint
textLock baseUrl id =
    url baseUrl [ "api", "text", String.fromInt id, "lock/" ] []



-- INVITE


inviteInstructor : String -> Endpoint
inviteInstructor baseUrl =
    url baseUrl [ "api", "instructor", "invite" ] []



-- QUERY PARAMS


{-| This conversion is meant to provide interoperability with the old way of
building querystrings. It would be better to build these as QueryParamters
from the start instead of converting after the fact.
-}
filterToStringQueryParam : String -> QueryParameter
filterToStringQueryParam val =
    let
        keyValueList =
            String.split "=" val
    in
    case keyValueList of
        key :: value :: [] ->
            Url.Builder.string key value

        _ ->
            Url.Builder.string "bad" "param"
