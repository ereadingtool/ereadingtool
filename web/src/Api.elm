port module Api exposing
    ( Cred
    , application
    , exposeToken
    , get
    , login
    , logout
    , viewerChanges
    )

import Browser
import Http
import Json.Decode as Decode exposing (Decoder, Value, field, string)
import Json.Decode.Pipeline exposing (required)



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


{-| Exposes the token outside this module

TODO: remove this. This should be considered a temporary measure for use while transitioning the
backend communication layer.

-}
exposeToken : Maybe Cred -> String
exposeToken maybeCred =
    case maybeCred of
        Just (Cred val) ->
            val

        Nothing ->
            ""



-- AUTH


port login : Value -> Cmd msg


port logout : () -> Cmd msg



-- PERSISTENCE


{-| Login status is solely determined by credentials stored in localstorage.

We subscribe to changes here. When a user logs in or out, we attempt to decode
a JSON string with their credentials. On success, we have a logged in user.
Otherwise, we have a guest.

-}
port onAuthStoreChange : (Value -> msg) -> Sub msg


viewerChanges : (Maybe viewer -> msg) -> Decoder (Cred -> viewer) -> Sub msg
viewerChanges toMsg decoder =
    onAuthStoreChange (\val -> toMsg (decodeFromChange decoder val))


decodeFromChange : Decoder (Cred -> viewer) -> Value -> Maybe viewer
decodeFromChange viewerDecoder val =
    Decode.decodeValue Decode.string val
        |> Result.andThen (Decode.decodeString (storageDecoder viewerDecoder))
        |> Result.toMaybe


storageDecoder : Decoder (Cred -> viewer) -> Decoder viewer
storageDecoder viewerDecoder =
    Decode.field "user" (decoderFromCred viewerDecoder)


decoderFromCred : Decoder (Cred -> a) -> Decoder a
decoderFromCred decoder =
    Decode.map2 (\fromCred cred -> fromCred cred)
        decoder
        credDecoder



-- APPLICATION


{-| application initializes the app with credentials from localstorage

We call this from Main, but actually initiliazing the app here restricts
access to the token to this module.

-}
application :
    Decoder (Cred -> user)
    ->
        { init : Maybe user -> ( model, Cmd msg )
        , update : msg -> model -> ( model, Cmd msg )
        , subscriptions : model -> Sub msg
        , view : model -> Browser.Document msg
        }
    -> Program Value model msg
application viewerDecoder config =
    let
        init flags =
            let
                maybeViewer =
                    Decode.decodeValue Decode.string flags
                        |> Result.andThen (Decode.decodeString (storageDecoder viewerDecoder))
                        |> Result.toMaybe
            in
            config.init maybeViewer
    in
    Browser.document
        { init = init
        , subscriptions = config.subscriptions
        , update = config.update
        , view = config.view
        }



-- HTTP


credHeader : Cred -> Http.Header
credHeader (Cred token) =
    Http.header "authorization" token


get :
    String
    -> Maybe Cred
    -> (Result Http.Error a -> msg)
    -> Decoder a
    -> Cmd msg
get endpoint maybeCred toMsg decoder =
    Http.request
        { method = "GET"
        , url = "http://localhost:8000/" ++ endpoint
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
