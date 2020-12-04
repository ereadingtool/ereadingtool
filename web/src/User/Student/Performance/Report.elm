module User.Student.Performance.Report exposing
    ( PerformanceMetrics
    , PerformanceReport
    , emptyPerformanceReport
    , metrics
    , performanceReportDecoder
    )

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (custom, required)


type alias PerformanceReport =
    { all : Dict String PerformanceMetrics
    , intermediateMid : Dict String PerformanceMetrics
    , intermediateHigh : Dict String PerformanceMetrics
    , advancedLow : Dict String PerformanceMetrics
    , advancedMid : Dict String PerformanceMetrics
    }


type alias PerformanceMetrics =
    { percentCorrect : Float
    , textsComplete : Int
    , totalTexts : Int
    }


emptyPerformanceReport : PerformanceReport
emptyPerformanceReport =
    { all = Dict.empty
    , intermediateMid = Dict.empty
    , intermediateHigh = Dict.empty
    , advancedLow = Dict.empty
    , advancedMid = Dict.empty
    }


metrics : String -> Dict String PerformanceMetrics -> PerformanceMetrics
metrics timePeriod metricsDict =
    case Dict.get timePeriod metricsDict of
        Just dict ->
            dict

        Nothing ->
            { percentCorrect = 0
            , textsComplete = 0
            , totalTexts = 0
            }



-- DECODE


performanceReportDecoder : Decoder PerformanceReport
performanceReportDecoder =
    Decode.succeed PerformanceReport
        |> custom (Decode.at [ "all", "categories" ] (Decode.dict metricsDecoder))
        |> custom (Decode.at [ "intermediate_mid", "categories" ] (Decode.dict metricsDecoder))
        |> custom (Decode.at [ "intermediate_high", "categories" ] (Decode.dict metricsDecoder))
        |> custom (Decode.at [ "advanced_low", "categories" ] (Decode.dict metricsDecoder))
        |> custom (Decode.at [ "advanced_mid", "categories" ] (Decode.dict metricsDecoder))


metricsDecoder : Decoder PerformanceMetrics
metricsDecoder =
    Decode.field "metrics"
        (Decode.succeed PerformanceMetrics
            |> required "percent_correct" (Decode.oneOf [ Decode.float, Decode.null 0 ])
            |> required "texts_complete" Decode.int
            |> required "total_texts" Decode.int
        )
