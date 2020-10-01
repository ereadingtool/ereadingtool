module Api.Config exposing
    ( Config
    , configDecoder
    , encodeShowHelp
    , init
    , mapShowHelp
    , restApiUrl
    , showHelp
    , websocketBaseUrl
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (custom, required)
import Json.Encode as Encode exposing (Value)


type Config
    = Config Internals


type alias Internals =
    { restApiUrl : String
    , websocketBaseUrl : String
    , showHelp : Bool
    }


init : Maybe Config -> Config
init maybeConfig =
    case maybeConfig of
        Just config ->
            config

        -- Here the URL has been changed for local development
        Nothing ->
            Config
                { restApiUrl = "https://api.stepstoadvancedreading.org"
                , websocketBaseUrl = "wss://api.stepstoadvancedreading.org"
                , showHelp = True
                }


restApiUrl : Config -> String
restApiUrl (Config internals) =
    internals.restApiUrl


websocketBaseUrl : Config -> String
websocketBaseUrl (Config internals) =
    internals.websocketBaseUrl


showHelp : Config -> Bool
showHelp (Config internals) =
    internals.showHelp


mapShowHelp : (Bool -> Bool) -> Config -> Config
mapShowHelp transform (Config internals) =
    Config { internals | showHelp = transform internals.showHelp }



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
        |> required "showHelp" Decode.bool


encodeShowHelp : Bool -> Value
encodeShowHelp show =
    Encode.object
        [ ( "showHelp", Encode.bool show ) ]
