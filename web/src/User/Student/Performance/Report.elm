module User.Student.Performance.Report exposing
    ( PerformanceMetrics
    , PerformanceReport
    , emptyPerformanceReport
    , metrics
    , performanceReportDecoder
    , view
    )

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (rowspan)
import Infobar exposing (view)
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
    { textsStarted : Int
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
            { textsStarted = 0
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
            -- |> required "percent_correct" (Decode.oneOf [ Decode.float, Decode.null 0 ])
            |> required "in_progress" Decode.int
            |> required "complete" Decode.int
            |> required "total_texts" Decode.int
        )



-- VIEW


view : PerformanceReport -> Html msg
view performanceReport =
    div []
        [ table [] <|
            [ tr []
                [ th [] [ text "Level" ]
                , th [] [ text "Time Period" ]
                , th [] [ text "Texts Started" ]
                , th [] [ text "Texts Completed" ]
                ]
            ]
                ++ viewPerformanceLevelRow "All" performanceReport.all
                ++ viewPerformanceLevelRow "Intermediate-Mid" performanceReport.intermediateMid
                ++ viewPerformanceLevelRow "Intermediate-High" performanceReport.intermediateHigh
                ++ viewPerformanceLevelRow "Advanced-Low" performanceReport.advancedLow
                ++ viewPerformanceLevelRow "Advanced-Mid" performanceReport.advancedMid
        ]


viewPerformanceLevelRow : String -> Dict String PerformanceMetrics -> List (Html msg)
viewPerformanceLevelRow level metricsDict =
    let
        cumulative =
            metrics "cumulative" metricsDict

        currentMonth =
            metrics "current_month" metricsDict

        pastMonth =
            metrics "past_month" metricsDict
    in
    [ tr []
        [ td [ rowspan 4 ] [ text level ]
        ]
    , tr []
        [ td [] [ text "Cumulative" ]
        , td [] [ viewTextsStartedCell cumulative ]
        , td [] [ viewTextsReadCell cumulative ]
        ]
    , tr []
        [ td [] [ text "Current Month" ]
        , td [] [ viewTextsStartedCell currentMonth ]
        , td [] [ viewTextsReadCell currentMonth ]
        ]
    , tr []
        [ td [] [ text "Past Month" ]
        , td [] [ viewTextsStartedCell pastMonth ]
        , td [] [ viewTextsReadCell pastMonth ]
        ]
    ]


viewTextsStartedCell : PerformanceMetrics -> Html msg
viewTextsStartedCell performanceMetrics =
    text <|
        String.join " " <|
            [ String.fromInt performanceMetrics.textsStarted
            , "out of"
            , String.fromInt performanceMetrics.totalTexts
            ]


viewTextsReadCell : PerformanceMetrics -> Html msg
viewTextsReadCell performanceMetrics =
    text <|
        String.join " " <|
            [ String.fromInt performanceMetrics.textsComplete
            , "out of"
            , String.fromInt performanceMetrics.totalTexts
            ]



-- viewPercentCorrectCell : PerformanceMetrics -> Html Msg
-- viewPercentCorrectCell metrics =
--     text <|
--         String.fromFloat metrics.percentCorrect
--             ++ "%"
