module Api.Config exposing
    ( Config
    , configDecoder
    , init
    , restApiUrl
    , websocketBaseUrl
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (custom, required)


type Config
    = Config Internals


type alias Internals =
    { restApiUrl : String
    , websocketBaseUrl : String
    }


init : Maybe Config -> Config
init maybeConfig =
    case maybeConfig of
        Just config ->
            config

        Nothing ->
            Config
                { restApiUrl = "https://api.stepstoadvancedreading.org"
                , websocketBaseUrl = "wss://api.stepstoadvancedreading.org"
                }


restApiUrl : Config -> String
restApiUrl (Config internals) =
    internals.restApiUrl


websocketBaseUrl : Config -> String
websocketBaseUrl (Config internals) =
    internals.websocketBaseUrl



-- SERIALIZATION


configDecoder : Decoder Config
configDecoder =
    Decode.succeed Config
        |> custom internalsDecoder


internalsDecoder : Decoder Internals
internalsDecoder =
    Decode.succeed Internals
        |> required "restApiUrl" Decode.string
        |> required "websocketBaseUrl" Decode.string
