module User.Student.Performance.Report exposing
    ( PerformanceReport
    , Tab(..)
    , emptyPerformanceReport
    , performanceReportDecoder
    , view
    )

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (class, rowspan)
import Html.Events exposing (onClick)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (custom, required)


type alias PerformanceReport =
    { completion : CompletionReport
    , comprehension : ComprehensionReport
    }


type Tab
    = Completion
    | Comprehension


type alias CompletionReport =
    { all : Dict String CompletionMetrics
    , intermediateMid : Dict String CompletionMetrics
    , intermediateHigh : Dict String CompletionMetrics
    , advancedLow : Dict String CompletionMetrics
    , advancedMid : Dict String CompletionMetrics
    }


type alias CompletionMetrics =
    { textsStarted : Int
    , textsComplete : Int
    , totalTexts : Int
    }


type alias ComprehensionReport =
    { all : ComprehensionMetrics
    , intermediateMid : ComprehensionMetrics
    , intermediateHigh : ComprehensionMetrics
    , advancedLow : ComprehensionMetrics
    , advancedMid : ComprehensionMetrics
    }


type alias ComprehensionMetrics =
    { firstTimeCorrectAnswers : Int
    , firstTimePercentCorrect : Float
    }



-- CREATE


emptyPerformanceReport : PerformanceReport
emptyPerformanceReport =
    { completion =
        { all = Dict.empty
        , intermediateMid = Dict.empty
        , intermediateHigh = Dict.empty
        , advancedLow = Dict.empty
        , advancedMid = Dict.empty
        }
    , comprehension =
        { all = emptyComprehensionMetrics
        , intermediateMid = emptyComprehensionMetrics
        , intermediateHigh = emptyComprehensionMetrics
        , advancedLow = emptyComprehensionMetrics
        , advancedMid = emptyComprehensionMetrics
        }
    }


emptyComprehensionMetrics : ComprehensionMetrics
emptyComprehensionMetrics =
    { firstTimeCorrectAnswers = 0
    , firstTimePercentCorrect = 0.0
    }



-- DECODE


performanceReportDecoder : Decoder PerformanceReport
performanceReportDecoder =
    Decode.map2 PerformanceReport
        completionReportDecoder
        comprehensionReportDecoder


completionReportDecoder : Decoder CompletionReport
completionReportDecoder =
    Decode.succeed CompletionReport
        |> custom (Decode.at [ "all", "categories" ] (Decode.dict completionMetricsDecoder))
        |> custom (Decode.at [ "intermediate_mid", "categories" ] (Decode.dict completionMetricsDecoder))
        |> custom (Decode.at [ "intermediate_high", "categories" ] (Decode.dict completionMetricsDecoder))
        |> custom (Decode.at [ "advanced_low", "categories" ] (Decode.dict completionMetricsDecoder))
        |> custom (Decode.at [ "advanced_mid", "categories" ] (Decode.dict completionMetricsDecoder))


completionMetricsDecoder : Decoder CompletionMetrics
completionMetricsDecoder =
    Decode.field "metrics"
        (Decode.succeed CompletionMetrics
            |> required "in_progress" Decode.int
            |> required "complete" Decode.int
            |> required "total_texts" Decode.int
        )


comprehensionReportDecoder : Decoder ComprehensionReport
comprehensionReportDecoder =
    Decode.succeed ComprehensionReport
        |> custom (Decode.at [ "all", "categories", "cumulative" ] comprehensionMetricsDecoder)
        |> custom (Decode.at [ "intermediate_mid", "categories", "cumulative" ] comprehensionMetricsDecoder)
        |> custom (Decode.at [ "intermediate_high", "categories", "cumulative" ] comprehensionMetricsDecoder)
        |> custom (Decode.at [ "advanced_low", "categories", "cumulative" ] comprehensionMetricsDecoder)
        |> custom (Decode.at [ "advanced_mid", "categories", "cumulative" ] comprehensionMetricsDecoder)


comprehensionMetricsDecoder : Decoder ComprehensionMetrics
comprehensionMetricsDecoder =
    Decode.field "metrics"
        (Decode.succeed ComprehensionMetrics
            |> required "first_time_correct" Decode.int
            |> required "percent_correct" (Decode.oneOf [ Decode.float, Decode.null 0 ])
        )



-- ACCESS


completionMetrics : String -> Dict String CompletionMetrics -> CompletionMetrics
completionMetrics timePeriod metricsDict =
    case Dict.get timePeriod metricsDict of
        Just dict ->
            dict

        Nothing ->
            { textsStarted = 0
            , textsComplete = 0
            , totalTexts = 0
            }



-- VIEW


view :
    { performanceReport : PerformanceReport
    , selectedTab : Tab
    , onSelectReport : Tab -> msg
    }
    -> Html msg
view { performanceReport, selectedTab, onSelectReport } =
    div []
        [ div [ class "performance-report-tabs" ]
            [ span
                [ case selectedTab of
                    Completion ->
                        class "selected-performance-report-tab"

                    Comprehension ->
                        class "performance-report-tab"
                , onClick (onSelectReport Completion)
                ]
                [ text "Completion" ]
            , span
                [ case selectedTab of
                    Completion ->
                        class "performance-report-tab"

                    Comprehension ->
                        class "selected-performance-report-tab"
                , onClick (onSelectReport Comprehension)
                ]
                [ text "First Time Comprehension" ]
            ]
        , case selectedTab of
            Completion ->
                viewCompletionReportTable performanceReport.completion

            Comprehension ->
                viewComprehensionReportTable performanceReport.comprehension
        ]



-- VIEW: COMPLETION


viewCompletionReportTable : CompletionReport -> Html msg
viewCompletionReportTable completion =
    table [] <|
        [ tr []
            [ th [] [ text "Level" ]
            , th [] [ text "Time Period" ]
            , th [] [ text "Texts Started" ]
            , th [] [ text "Texts Completed" ]
            ]
        ]
            ++ viewCompletionRow "All" completion.all
            ++ viewCompletionRow "Intermediate-Mid" completion.intermediateMid
            ++ viewCompletionRow "Intermediate-High" completion.intermediateHigh
            ++ viewCompletionRow "Advanced-Low" completion.advancedLow
            ++ viewCompletionRow "Advanced-Mid" completion.advancedMid


viewCompletionRow : String -> Dict String CompletionMetrics -> List (Html msg)
viewCompletionRow level metricsDict =
    let
        cumulative =
            completionMetrics "cumulative" metricsDict

        currentMonth =
            completionMetrics "current_month" metricsDict

        pastMonth =
            completionMetrics "past_month" metricsDict
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


viewTextsStartedCell : CompletionMetrics -> Html msg
viewTextsStartedCell metrics =
    text <|
        String.join " " <|
            [ String.fromInt metrics.textsStarted
            , "out of"
            , String.fromInt metrics.totalTexts
            ]


viewTextsReadCell : CompletionMetrics -> Html msg
viewTextsReadCell metrics =
    text <|
        String.join " " <|
            [ String.fromInt metrics.textsComplete
            , "out of"
            , String.fromInt metrics.totalTexts
            ]



-- VIEW: COMPREHENSION


viewComprehensionReportTable : ComprehensionReport -> Html msg
viewComprehensionReportTable comprehension =
    table [] <|
        [ tr []
            [ th [] [ text "Level" ]
            , th [] [ text "Answers Correct" ]
            , th [] [ text "Percent Correct" ]
            ]
        ]
            ++ viewComprehensionRow "All" comprehension.all
            ++ viewComprehensionRow "Intermediate-Mid" comprehension.intermediateMid
            ++ viewComprehensionRow "Intermediate-High" comprehension.intermediateHigh
            ++ viewComprehensionRow "Advanced-Low" comprehension.advancedLow
            ++ viewComprehensionRow "Advanced-Mid" comprehension.advancedMid


viewComprehensionRow : String -> ComprehensionMetrics -> List (Html msg)
viewComprehensionRow level metrics =
    [ tr []
        [ td [] [ text level ]
        , td [] [ text (String.fromInt metrics.firstTimeCorrectAnswers) ]
        , td []
            [ text <|
                String.fromFloat metrics.firstTimePercentCorrect
                    ++ "%"
            ]
        ]
    ]
