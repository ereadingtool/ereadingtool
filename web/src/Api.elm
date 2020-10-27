port module Api exposing
    ( AuthError
    , AuthSuccess
    , Cred
    , application
    , authErrorMessage
    , authResult
    , authSuccessMessage
    , delete
    , get
    , login
    , logout
    , performanceReportLink
    , post
    , postDetailed
    , postTask
    , put
    , putDetailed
    , toggleShowHelp
    , viewerChanges
    , websocketConnect
    , websocketDisconnect
    , websocketReceive
    , websocketSend
    )

import Api.Config as Config exposing (Config)
import Api.Endpoint as Endpoint exposing (Endpoint)
import Api.WebSocket as WebSocket exposing (Address, WebSocketCmd, WebSocketMsg)
import Browser
import Browser.Navigation as Nav
import Http
import Http.Detailed
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, Value, field, string)
import Json.Decode.Pipeline exposing (required)
import Role exposing (Role)
import Task exposing (Task, perform)
import Url exposing (Url)



-- CRED


{-| Authentication credentials

We define Cred to limit the visibility of the token to this module.

-}
type Cred
    = Cred String


credDecoder : Decoder Cred
credDecoder =
    Decode.succeed Cred
        |> required "token" Decode.string



-- HELP


port toggleShowHelp : Value -> Cmd msg



-- AUTH


type alias AuthResponse =
    { result : String
    , message : String
    }


decodeAuthResponse : Decoder AuthResponse
decodeAuthResponse =
    Decode.succeed AuthResponse
        |> required "result" Decode.string
        |> required "message" Decode.string


type AuthSuccess
    = AuthSuccess String


authSuccessMessage : AuthSuccess -> String
authSuccessMessage (AuthSuccess val) =
    val


type AuthError
    = AuthError String


authErrorMessage : AuthError -> String
authErrorMessage (AuthError err) =
    err


port onAuthResponse : (Value -> msg) -> Sub msg


authResult : (Result AuthError AuthSuccess -> msg) -> Sub msg
authResult toMsg =
    onAuthResponse (\val -> toMsg (toAuthResult (Decode.decodeValue decodeAuthResponse val)))


toAuthResult : Result Decode.Error AuthResponse -> Result AuthError AuthSuccess
toAuthResult result =
    case result of
        Ok authResponse ->
            case authResponse.result of
                "success" ->
                    Ok (AuthSuccess authResponse.message)

                "error" ->
                    Err (AuthError authResponse.message)

                _ ->
                    Err (AuthError "An internal error occured. Please contact the developers.")

        Err err ->
            Err
                (AuthError <|
                    "An internal error occured. Please contact the developers and mention that "
                        ++ Decode.errorToString err
                )


port login : Value -> Cmd msg


port logout : () -> Cmd msg



-- PERSISTENCE


{-| Login status is solely determined by credentials stored in localstorage.

We subscribe to changes here. When a user logs in or out, we attempt to decode
a JSON string with their credentials. On success, we have a logged in user.
Otherwise, we have a guest.

-}
port onAuthStoreChange : (Value -> msg) -> Sub msg


viewerChanges : (Maybe viewer -> msg) -> Decoder (Cred -> Id -> Role -> viewer) -> Sub msg
viewerChanges toMsg decoder =
    onAuthStoreChange (\val -> toMsg (decodeFromChange decoder val))


decodeFromChange : Decoder (Cred -> Id -> Role -> viewer) -> Value -> Maybe viewer
decodeFromChange viewerDecoder val =
    Decode.decodeValue (storageDecoder viewerDecoder) val
        |> Result.toMaybe


storageDecoder : Decoder (Cred -> Id -> Role -> viewer) -> Decoder viewer
storageDecoder viewerDecoder =
    Decode.field "user" (decoderFromCred viewerDecoder)


decoderFromCred : Decoder (Cred -> Id -> Role -> a) -> Decoder a
decoderFromCred decoder =
    Decode.map4 (\fromCred cred -> fromCred cred)
        decoder
        credDecoder
        (Decode.field "id" Id.decoder)
        (Decode.field "role" Decode.string
            |> Decode.andThen Role.decoder
        )



-- APPLICATION


{-| application initializes the app with credentials from localstorage

We call this from Main, but actually initiliazing the app here restricts
access to the token to this module.

-}
application :
    Decoder (Cred -> Id -> Role -> viewer)
    ->
        { init : { maybeConfig : Maybe Config, maybeViewer : Maybe viewer } -> Url -> Nav.Key -> ( model, Cmd msg )
        , onUrlChange : Url -> msg
        , onUrlRequest : Browser.UrlRequest -> msg
        , update : msg -> model -> ( model, Cmd msg )
        , subscriptions : model -> Sub msg
        , view : model -> Browser.Document msg
        }
    -> Program Value model msg
application viewerDecoder config =
    let
        init flags url navKey =
            let
                decodedFlags =
                    { maybeViewer =
                        Decode.decodeValue (storageDecoder viewerDecoder) flags
                            |> Result.toMaybe
                    , maybeConfig =
                        Decode.decodeValue Config.configDecoder flags
                            |> Result.toMaybe
                    }
            in
            config.init decodedFlags url navKey
    in
    Browser.application
        { init = init
        , onUrlChange = config.onUrlChange
        , onUrlRequest = config.onUrlRequest
        , subscriptions = config.subscriptions
        , update = config.update
        , view = config.view
        }



-- HTTP


credHeader : Cred -> Http.Header
credHeader (Cred token) =
    Http.header "Authorization" ("Bearer " ++ token)


get :
    Endpoint
    -> Maybe Cred
    -> (Result Http.Error a -> msg)
    -> Decoder a
    -> Cmd msg
get url maybeCred toMsg decoder =
    Endpoint.request
        { method = "GET"
        , url = url
        , expect = Http.expectJson toMsg decoder
        , headers =
            case maybeCred of
                Just cred ->
                    [ credHeader cred ]

                Nothing ->
                    []
        , body = Http.emptyBody
        , timeout = Nothing
        , tracker = Nothing
        }


put :
    Endpoint
    -> Maybe Cred
    -> Http.Body
    -> (Result Http.Error a -> msg)
    -> Decode.Decoder a
    -> Cmd msg
put url maybeCred body toMsg decoder =
    Endpoint.request
        { method = "PUT"
        , url = url
        , expect = Http.expectJson toMsg decoder
        , headers =
            case maybeCred of
                Just cred ->
                    [ credHeader cred ]

                Nothing ->
                    []
        , body = body
        , timeout = Nothing
        , tracker = Nothing
        }


post :
    Endpoint
    -> Maybe Cred
    -> Http.Body
    -> (Result Http.Error a -> msg)
    -> Decode.Decoder a
    -> Cmd msg
post url maybeCred body toMsg decoder =
    Endpoint.request
        { method = "POST"
        , url = url
        , expect = Http.expectJson toMsg decoder
        , headers =
            case maybeCred of
                Just cred ->
                    [ credHeader cred ]

                Nothing ->
                    []
        , body = body
        , timeout = Nothing
        , tracker = Nothing
        }


delete :
    Endpoint
    -> Maybe Cred
    -> Http.Body
    -> (Result Http.Error a -> msg)
    -> Decode.Decoder a
    -> Cmd msg
delete url maybeCred body toMsg decoder =
    Endpoint.request
        { method = "DELETE"
        , url = url
        , expect = Http.expectJson toMsg decoder
        , headers =
            case maybeCred of
                Just cred ->
                    [ credHeader cred ]

                Nothing ->
                    []
        , body = body
        , timeout = Nothing
        , tracker = Nothing
        }


{-| Detailed HTTP calls expose Metadata so we can show users error messages
sent back from the server
-}
putDetailed :
    Endpoint
    -> Maybe Cred
    -> Http.Body
    -> (Result (Http.Detailed.Error String) ( Http.Metadata, a ) -> msg)
    -> Decode.Decoder a
    -> Cmd msg
putDetailed url maybeCred body toMsg decoder =
    Endpoint.request
        { method = "PUT"
        , url = url
        , expect = Http.Detailed.expectJson toMsg decoder
        , headers =
            case maybeCred of
                Just cred ->
                    [ credHeader cred ]

                Nothing ->
                    []
        , body = body
        , timeout = Nothing
        , tracker = Nothing
        }


postDetailed :
    Endpoint
    -> Maybe Cred
    -> Http.Body
    -> (Result (Http.Detailed.Error String) ( Http.Metadata, a ) -> msg)
    -> Decode.Decoder a
    -> Cmd msg
postDetailed url maybeCred body toMsg decoder =
    Endpoint.request
        { method = "POST"
        , url = url
        , expect = Http.Detailed.expectJson toMsg decoder
        , headers =
            case maybeCred of
                Just cred ->
                    [ credHeader cred ]

                Nothing ->
                    []
        , body = body
        , timeout = Nothing
        , tracker = Nothing
        }


postTask :
    Endpoint
    -> Maybe Cred
    -> Http.Body
    -> Decode.Decoder a
    -> Task Http.Error a
postTask url maybeCred body decoder =
    Endpoint.task
        { method = "POST"
        , url = url
        , headers =
            case maybeCred of
                Just cred ->
                    [ credHeader cred ]

                Nothing ->
                    []
        , body = body
        , resolver =
            Http.stringResolver <|
                handleJsonResponse decoder
        , timeout = Nothing
        }


handleJsonResponse : Decoder a -> Http.Response String -> Result Http.Error a
handleJsonResponse decoder response =
    case response of
        Http.BadUrl_ url ->
            Err (Http.BadUrl url)

        Http.Timeout_ ->
            Err Http.Timeout

        Http.BadStatus_ { statusCode } _ ->
            Err (Http.BadStatus statusCode)

        Http.NetworkError_ ->
            Err Http.NetworkError

        Http.GoodStatus_ _ body ->
            case Decode.decodeString decoder body of
                Err _ ->
                    Err (Http.BadBody body)

                Ok result ->
                    Ok result



-- EXTERNAL LINKS


performanceReportLink : String -> Maybe Cred -> Int -> String
performanceReportLink baseUrl maybeCred id =
    Endpoint.performanceReportLink baseUrl id <|
        case maybeCred of
            Just (Cred cred) ->
                cred

            Nothing ->
                ""



-- WEBSOCKETS


port receiveSocketMsg : (Value -> msg) -> Sub msg


port sendSocketCommand : Value -> Cmd msg


websocketConnect :
    { name : String, address : Address }
    -> Maybe Cred
    -> Cmd msg
websocketConnect { name, address } maybeCred =
    case maybeCred of
        Just (Cred token) ->
            WebSocket.send sendSocketCommand <|
                WebSocket.Connect
                    { name = name
                    , address = WebSocket.unwrap address ++ "?" ++ token
                    , protocol = ""
                    }

        Nothing ->
            Cmd.none


websocketSend : { name : String, content : Value } -> Cmd msg
websocketSend message =
    WebSocket.send sendSocketCommand <|
        WebSocket.Send message


websocketReceive : (Result Decode.Error WebSocketMsg -> msg) -> Sub msg
websocketReceive toMsg =
    receiveSocketMsg <| WebSocket.receive toMsg


websocketDisconnect : String -> Cmd msg
websocketDisconnect name =
    WebSocket.send sendSocketCommand <|
        WebSocket.Close { name = name }
