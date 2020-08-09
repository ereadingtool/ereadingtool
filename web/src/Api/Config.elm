module Api.Config exposing (Config, configDecoder, init, restApiUrl)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (custom, required)


type Config
    = Config Internals


type alias Internals =
    { restApiUrl : String
    }


init : Maybe Config -> Config
init maybeConfig =
    case maybeConfig of
        Just config ->
            config

        Nothing ->
            Config
                { restApiUrl = "https://api.stepstoadvancedreading.org"
                }


restApiUrl : Config -> String
restApiUrl (Config internals) =
    internals.restApiUrl



-- SERIALIZATION


configDecoder : Decoder Config
configDecoder =
    Decode.succeed Config
        |> custom internalsDecoder


internalsDecoder : Decoder Internals
internalsDecoder =
    Decode.succeed Internals
        |> required "restApiUrl" Decode.string
