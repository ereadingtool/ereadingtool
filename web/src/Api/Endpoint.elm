module Api.Endpoint exposing
    ( Endpoint
    , consentToResearch
    , createText
    , createTranslation
    , createWord
    , filterToStringQueryParam
    , forgotPassword
    , instructorProfile
    , instructorSignup
    , inviteInstructor
    , matchTranslation
    , mergeWords
    , performanceReportLink
    , request
    , resetPassword
    , studentProfile
    , studentSignup
    , task
    , text
    , textLock
    , textSearch
    , translation
    , validateUsername
    , word
    )

import Http
import Task exposing (Task)
import Url.Builder exposing (QueryParameter)
import User.Student.Performance.Report exposing (performanceReportDecoder)


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



-- TASKS


task :
    { method : String
    , headers : List Http.Header
    , url : Endpoint
    , body : Http.Body
    , resolver : Http.Resolver Http.Error a
    , timeout : Maybe Float
    }
    -> Task Http.Error a
task config =
    Http.task
        { method = config.method
        , headers = config.headers
        , url = unwrap config.url
        , body = config.body
        , resolver = config.resolver
        , timeout = config.timeout
        }



-- ENDPOINTS


forgotPassword : String -> Endpoint
forgotPassword baseUrl =
    url baseUrl [ "api", "password", "reset" ] []


resetPassword : String -> Endpoint
resetPassword baseUrl =
    url baseUrl [ "api", "password", "reset", "confirm" ] []


instructorSignup : String -> Endpoint
instructorSignup baseUrl =
    url baseUrl [ "api", "instructor", "signup" ] []


studentSignup : String -> Endpoint
studentSignup baseUrl =
    url baseUrl [ "api", "student", "signup" ] []



-- PROFILE


studentProfile : String -> Int -> Endpoint
studentProfile baseUrl id =
    url baseUrl [ "api", "student", String.fromInt id ] []


instructorProfile : String -> Int -> Endpoint
instructorProfile baseUrl id =
    url baseUrl [ "api", "instructor", String.fromInt id ] []


consentToResearch : String -> Int -> Endpoint
consentToResearch baseUrl id =
    url baseUrl [ "api", "student", String.fromInt id, "consent_to_research" ] []


validateUsername : String -> Endpoint
validateUsername baseUrl =
    url baseUrl [ "api", "username" ] []



-- TEXT SEARCH


textSearch : String -> List QueryParameter -> Endpoint
textSearch baseUrl queryParameters =
    url baseUrl [ "api", "text" ] queryParameters



-- TEXT CREATE AND EDIT


createText : String -> Endpoint
createText baseUrl =
    url baseUrl [ "api", "text" ] []


text : String -> Int -> List ( String, String ) -> Endpoint
text baseUrl id queryParameters =
    url baseUrl
        [ "api", "text", String.fromInt id ]
        (List.map
            (\qp ->
                Url.Builder.string
                    (Tuple.first qp)
                    (Tuple.second qp)
            )
            queryParameters
        )


textLock : String -> Int -> Endpoint
textLock baseUrl id =
    url baseUrl [ "api", "text", String.fromInt id, "lock" ] []



-- WORDS


createWord : String -> Endpoint
createWord baseUrl =
    url baseUrl [ "api", "text", "word" ] []


word : String -> Int -> Endpoint
word baseUrl id =
    url baseUrl [ "api", "text", "word", String.fromInt id ] []


mergeWords : String -> Endpoint
mergeWords baseUrl =
    url baseUrl [ "api", "text", "word", "compound" ] []



-- TRANSLATIONS


createTranslation : String -> Int -> Endpoint
createTranslation baseUrl wordId =
    url baseUrl
        [ "api"
        , "text"
        , "word"
        , String.fromInt wordId
        , "translation"
        ]
        []


translation : String -> Int -> Int -> Endpoint
translation baseUrl wordId translationId =
    url baseUrl
        [ "api"
        , "text"
        , "word"
        , String.fromInt wordId
        , "translation"
        , String.fromInt translationId
        ]
        []


matchTranslation : String -> Endpoint
matchTranslation baseUrl =
    url baseUrl [ "api", "text", "translations", "match" ] []



-- INVITE


inviteInstructor : String -> Endpoint
inviteInstructor baseUrl =
    url baseUrl [ "api", "instructor", "invite" ] []



-- EXTERNAL LINKS


performanceReportLink : String -> Int -> String -> String
performanceReportLink baseUrl id token =
    Url.Builder.crossOrigin baseUrl
        [ "profile"
        , "student"
        , String.fromInt id
        , "performance_report.pdf"
        ]
        [ Url.Builder.string "token" token ]



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
