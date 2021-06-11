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
    { all : Dict String ComprehensionMetrics
    , intermediateMid : Dict String ComprehensionMetrics
    , intermediateHigh : Dict String ComprehensionMetrics
    , advancedLow : Dict String ComprehensionMetrics
    , advancedMid : Dict String ComprehensionMetrics
    }


type alias ComprehensionMetrics =
    { firstTimeCorrectAnswers : Int
    , firstTimeCorrectTotalAnswers : Int
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
        { all = Dict.empty
        , intermediateMid = Dict.empty
        , intermediateHigh = Dict.empty
        , advancedLow = Dict.empty
        , advancedMid = Dict.empty
        }
    -- , comprehension =
    --     { all = emptyComprehensionMetrics
    --     , intermediateMid = emptyComprehensionMetrics
    --     , intermediateHigh = emptyComprehensionMetrics
    --     , advancedLow = emptyComprehensionMetrics
    --     , advancedMid = emptyComprehensionMetrics
    --     }
    }


emptyComprehensionMetrics : ComprehensionMetrics
emptyComprehensionMetrics =
    { firstTimeCorrectAnswers = 0
    , firstTimeCorrectTotalAnswers = 0
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
        |> custom (Decode.at [ "all", "categories" ] (Decode.dict comprehensionMetricsDecoder))
        |> custom (Decode.at [ "intermediate_mid", "categories" ] (Decode.dict comprehensionMetricsDecoder))
        |> custom (Decode.at [ "intermediate_high", "categories" ] (Decode.dict comprehensionMetricsDecoder))
        |> custom (Decode.at [ "advanced_low", "categories" ] (Decode.dict comprehensionMetricsDecoder))
        |> custom (Decode.at [ "advanced_mid", "categories" ] (Decode.dict comprehensionMetricsDecoder))


comprehensionMetricsDecoder : Decoder ComprehensionMetrics
comprehensionMetricsDecoder =
    Decode.at ["metrics", "first_time_correct"]
        (Decode.succeed ComprehensionMetrics
            |> required "correct_answers" Decode.int
            |> required "total_answers" Decode.int
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


comprehensionMetrics : String -> Dict String ComprehensionMetrics -> ComprehensionMetrics
comprehensionMetrics timePeriod metricsDict =
    case Dict.get timePeriod metricsDict of
        Just dict ->
            dict

        Nothing ->
            { firstTimeCorrectAnswers = 0
            , firstTimeCorrectTotalAnswers = 0
            , firstTimePercentCorrect = 0.0
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
            , th [] [ text "Time Period" ]
            , th [] [ text "Answers Correct" ]
            , th [] [ text "Percent Correct" ]
            ]
        ]
            ++ viewComprehensionRow "All" comprehension.all
            ++ viewComprehensionRow "Intermediate-Mid" comprehension.intermediateMid
            ++ viewComprehensionRow "Intermediate-High" comprehension.intermediateHigh
            ++ viewComprehensionRow "Advanced-Low" comprehension.advancedLow
            ++ viewComprehensionRow "Advanced-Mid" comprehension.advancedMid


viewComprehensionRow : String -> Dict String ComprehensionMetrics -> List (Html msg)
viewComprehensionRow level metricsDict =
    let
        cumulative =
            comprehensionMetrics "cumulative" metricsDict

        currentMonth =
            comprehensionMetrics "current_month" metricsDict

        pastMonth =
            comprehensionMetrics "past_month" metricsDict
    in
    [ tr []
        [ td [ rowspan 4 ] [ text level ]
        ]
    , tr []
        [ td [] [ text "Cumulative" ]
        , td [] [ viewAnswersCell cumulative ]
        , td [] [ viewPercentCorrectCell cumulative ]
        ]
    , tr []
        [ td [] [ text "Current Month" ]
        , td [] [ viewAnswersCell currentMonth ]
        , td [] [ viewPercentCorrectCell currentMonth ]
        ]
    , tr []
        [ td [] [ text "Past Month" ]
        , td [] [ viewAnswersCell pastMonth ]
        , td [] [ viewPercentCorrectCell pastMonth ]
        ]
    ]


viewAnswersCell : ComprehensionMetrics -> Html msg
viewAnswersCell metrics =
    text <|
        String.join " " <|
            [ String.fromInt metrics.firstTimeCorrectAnswers
            , "out of"
            , String.fromInt metrics.firstTimeCorrectTotalAnswers
            ]

viewPercentCorrectCell : ComprehensionMetrics -> Html msg
viewPercentCorrectCell metrics =
    text <|
        String.fromFloat metrics.firstTimePercentCorrect ++ "%"
