module Pages.Guide.Priority exposing (..)


import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Markdown
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)
import Help.Activities exposing (..)

page : Page Params Model Msg
page =
    Page.application
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , save = save
        , load = load
        }

type alias Model =
    { activities : Dict String Activity }    



-- INIT


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared { params } =
    ( { activities = initActivitiesHelper }
    , Cmd.none
    )


initActivitiesHelper : Dict String Activity
initActivitiesHelper =
    Dict.fromList
        [ ( "Activity1"
          , Activity
                (Dict.fromList
                    [ ( "Question1"
                      , Question
                            (Dict.fromList
                                [ ( "Answer1", Answer "exbain" False False )
                                , ( "Answer2", Answer "hasteled" True False )
                                , ( "Answer3", Answer "fornoy" True False )
                                , ( "Answer4", Answer "calput" False False )
                                ]
                            )
                            { showButton = False, showSolution = False}
                      )
                    ]
                )
          )
        , ( "Activity2"
          , Activity
                (Dict.fromList
                    [ ( "Question1"
                      , Question
                            (Dict.fromList
                                [ ( "Answer1", Answer "noun" False False )
                                , ( "Answer2", Answer "verb" False False )
                                , ( "Answer3", Answer "adjective" True False )
                                , ( "Answer4", Answer "adverb" False False )
                                , ( "Answer5", Answer "conjunction" False False )
                                ]
                            )
                            { showButton = False, showSolution = False}
                      )
                    , ( "Question2"
                      , Question
                            (Dict.fromList
                                [ ( "Answer1", Answer "noun" False False )
                                , ( "Answer2", Answer "verb" True False )
                                , ( "Answer3", Answer "adjective" False False )
                                , ( "Answer4", Answer "adverb" False False )
                                , ( "Answer5", Answer "conjunction" False False )
                                ]
                            )
                            { showButton = False, showSolution = False}
                      )
                    , ( "Question3"
                      , Question
                            (Dict.fromList
                                [ ( "Answer1", Answer "noun" True False )
                                , ( "Answer2", Answer "verb" False False )
                                , ( "Answer3", Answer "adjective" False False )
                                , ( "Answer4", Answer "adverb" False False )
                                , ( "Answer5", Answer "conjunction" False False )
                                ]
                            )
                            { showButton = False, showSolution = False}
                      )
                    , ( "Question4"
                      , Question
                            (Dict.fromList
                                [ ( "Answer1", Answer "noun" False False )
                                , ( "Answer2", Answer "verb" False False )
                                , ( "Answer3", Answer "adjective" True False )
                                , ( "Answer4", Answer "adverb" False False )
                                , ( "Answer5", Answer "conjunction" False False )
                                ]
                            )
                            { showButton = False, showSolution = False}
                      )
                    , ( "Question5"
                      , Question
                            (Dict.fromList
                                [ ( "Answer1", Answer "noun" False False )
                                , ( "Answer2", Answer "verb" False False )
                                , ( "Answer3", Answer "adjective" False False )
                                , ( "Answer4", Answer "adverb" False False )
                                , ( "Answer5", Answer "conjunction" True False )
                                ]
                            )
                            { showButton = False, showSolution = False}
                      )
                    , ( "Question6"
                      , Question
                            (Dict.fromList
                                [ ( "Answer1", Answer "noun" False False )
                                , ( "Answer2", Answer "verb" False False )
                                , ( "Answer3", Answer "adjective" False False )
                                , ( "Answer4", Answer "adverb" True False )
                                , ( "Answer5", Answer "conjunction" False False )
                                ]
                            )
                            { showButton = False, showSolution = False}
                      )
                    ]
                )
          )
        , ( "Activity3"
          , Activity
                (Dict.fromList
                    [ ( "Question1"
                      , Question
                            (Dict.fromList
                                [ ( "Answer1", Answer "foslaint" False False )
                                , ( "Answer2", Answer "fornoy" True False )
                                , ( "Answer3", Answer "divey" False False )
                                , ( "Answer4", Answer "calbained" True False )
                                , ( "Answer5", Answer "bazad" True False )
                                , ( "Answer6", Answer "fisd" True False )
                                ]
                            )
                            { showButton = False, showSolution = False}
                      )
                    ]
                )
          )
        ]



-- UPDATE


type Msg
    = UpdateAnswer String String String
    | RevealSolution String String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateAnswer activity question answer ->
            let
                updatedActivities = accessActivity model activity
                    |> accessQuestion question
                    |> accessAnswer answer
                    |> updateAnswer
                    |> updateQuestionShowsButton model activity question answer
                    |> updateActivity model activity question
                    |> updateActivities model activity
            in
            ( { model | activities = updatedActivities }
            , Cmd.none
            )

        RevealSolution activity question ->
            let
                -- maybeActivity =
                --     Dict.get activity model.activities

                -- maybeQuestion = case maybeActivity of
                --     Just ac ->
                --         Dict.get question (questions ac)
                --     Nothing -> Maybe.map identity Nothing

                -- updatedQuestion = case maybeQuestion of
                --     Just q -> Question (answers q) { showButton = True, showSolution = True }
                --     Nothing -> Question (Dict.fromList []) { showButton = False, showSolution = False }

                -- updatedActivity =
                --     case maybeActivity of
                --         Just ac ->
                --             Activity (Dict.update question (Maybe.map (\_ -> updatedQuestion)) (questions ac))

                --         Nothing ->
                --             Activity (Dict.fromList []) 

                -- updatedActivities =
                --     Dict.update activity (Maybe.map (\_ -> updatedActivity)) model.activities
                updatedActivities = accessActivity model activity
                    |> accessQuestion question
                    |> updateQuestionShowsSolution
                    |> updateActivity model activity question
                    |> updateActivities model activity
            in
            ( { model | activities = updatedActivities }, Cmd.none )


accessActivity : Model -> String -> Maybe Activity
accessActivity model activity =
    Dict.get activity model.activities

accessQuestion : String -> Maybe Activity -> Maybe Question
accessQuestion questionKey maybeActivity =
        case maybeActivity of
            Just ac ->
                Dict.get questionKey (questions ac)

            Nothing ->
                Maybe.map identity Nothing

accessAnswer : String -> Maybe Question -> Maybe Answer
accessAnswer answer maybeQuestion =
    case maybeQuestion of
        Just q -> 
            Dict.get answer (answers q)

        Nothing -> 
            Just (Answer "" False False)

clearQuestion : Maybe Question -> Question
clearQuestion maybeQuestion =
    case maybeQuestion of
        Just q ->
            Question (Dict.map (\_ an -> { an | selected = False }) (answers q)) { showButton = True, showSolution = False}

        Nothing ->
            Question (Dict.fromList []) { showButton = False, showSolution = False} 

updateAnswer : Maybe Answer -> Maybe Answer
updateAnswer maybeAnswer =
    case maybeAnswer of
        Just an ->
            Just (Answer an.answer an.correct (not an.selected))

        Nothing ->
            Just (Answer "" False False)

updateQuestionShowsButton : Model -> String -> String -> String -> Maybe Answer -> Question
updateQuestionShowsButton model activityKey questionKey answerKey updatedAnswer =
    let
        clearedQuestion = accessActivity model activityKey
                |> accessQuestion questionKey
                |> clearQuestion
    in
        Question (Dict.update answerKey (\_ -> updatedAnswer) (answers clearedQuestion)) { showButton = True, showSolution = False }


updateQuestionShowsSolution : Maybe Question -> Question
updateQuestionShowsSolution maybeQuestion = 
    case maybeQuestion of
        Just q -> Question (answers q) { showButton = True, showSolution = True }
        Nothing -> Question (Dict.fromList []) { showButton = False, showSolution = False }

updateActivity : Model -> String -> String -> Question -> Activity
updateActivity model activityKey questionKey updatedQuestion =
    let 
        maybeActivity = accessActivity model activityKey
    in
    case maybeActivity of
        Just ac ->
            Activity (Dict.update questionKey (Maybe.map (\_ -> updatedQuestion)) (questions ac))

        Nothing ->
            Activity (Dict.fromList [])

updateActivities : Model -> String -> Activity -> Dict String Activity
updateActivities model activityKey updatedActivity =
    Dict.update activityKey (Maybe.map (\_ -> updatedActivity)) model.activities
 

 
-- VIEW


type alias Params =
    ()


view : Model -> Document Msg
view model =
    { title = "Guide | Priority"
    , body =
        [ div [ id "body" ]
            [ div [ id "about" ]
                [ div [ id "about-box" ]
                    [ div [ id "title" ] [ text "Priority" ]
                    , viewTabs
                    , viewFirstSection
                    , viewSecondSection
                    , viewFirstQuestion model
                    , viewThirdSection
                    , viewFourthSection
                    , viewSecondQuestion model
                    , viewThirdQuestion model
                    , viewFourthQuestion model
                    , viewFifthQuestion model
                    , viewSixthQuestion model
                    , viewSeventhQuestion model
                    , viewFifthSection
                    , viewSixthSection
                    , viewEigthQuestion model
                    , viewSeventhSection
                    ]
                ]
            ]
        ]
    }


viewFirstQuestion : Model -> Html Msg
viewFirstQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity1" "Question1"

        answerCorrect =
            checkAnswerCorrect model "Activity1" "Question1"

        solutionVisible =
            checkButtonClicked model "Activity1" "Question1"
    in
    div []
        [ Html.div [] [ text "Based on frequency alone, which of these four words should you definitely look up?" ]
        , Html.form []
            [ input [ type_ "radio", name "activity1_question1", id "a1q1first", class "guide-question", onClick (UpdateAnswer "Activity1" "Question1" "Answer1") ] []
            , label [ for "a1q1first" ] [ getAnswerText model "Activity1" "Question1" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question1", id "a1q1second", class "guide-question", onClick (UpdateAnswer "Activity1" "Question1" "Answer2") ] []
            , label [ for "a1q1second" ] [ getAnswerText model "Activity1" "Question1" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question1", id "a1q1third", class "guide-question", onClick (UpdateAnswer "Activity1" "Question1" "Answer3") ] []
            , label [ for "a1q1third" ] [ getAnswerText model "Activity1" "Question1" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question1", id "a1q1fourth", class "guide-question", onClick (UpdateAnswer "Activity1" "Question1" "Answer4") ] []
            , label [ for "a1q1fourth" ] [ getAnswerText model "Activity1" "Question1" "Answer4" ]
            ]
        , div []
            [ if answerButtonVisible then
                div []
                    [ button [ onClick (RevealSolution "Activity1" "Question1") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct_answer" ]

                             else
                                div [ class "incorrect_answer" ]
                            )
                                [ Html.text "Hasteled -- should be a high priority since it occurs three times in the last five lines"
                                , Html.br [] []
                                , Html.text "Fornoy -- should also be a priority, since it occurs twice in two different places in the text"
                                , Html.text """Exbain -- should be a low priority. It occurs only once, and in the context it’s clear that it has to mean something 
                                like "bench, seat, or cushion." Unless the word is absolutely key to a comprehension question, having the sense that it is 
                                something in the range of "bench, seat, cushion" is probably sufficient."""
                                , Html.br [] []
                                , Html.text """Calput -- should be a low priority. It occurs only once, and in the context it’s clear that it has to be something 
                                like "position, tilt, twist, bend of his head."""
                                ]

                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewSecondQuestion : Model -> Html Msg
viewSecondQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity2" "Question1"

        answerCorrect =
            checkAnswerCorrect model "Activity2" "Question1"

        solutionVisible =
            checkButtonClicked model "Activity2" "Question1"
    in
    div []
        [ Html.div [] [ text "trathmollated" ]
        , Html.form []
            [ input [ type_ "radio", name "activity2_question1", id "a2q1first", class "guide-question", onClick (UpdateAnswer "Activity2" "Question1" "Answer1") ] []
            , label [ for "a2q1first" ] [ getAnswerText model "Activity2" "Question1" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question1", id "a2q1second", class "guide-question", onClick (UpdateAnswer "Activity2" "Question1" "Answer2") ] []
            , label [ for "a2q1second" ] [ getAnswerText model "Activity2" "Question1" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question1", id "a2q1third", class "guide-question", onClick (UpdateAnswer "Activity2" "Question1" "Answer3") ] []
            , label [ for "a2q1third" ] [ getAnswerText model "Activity2" "Question1" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question1", id "a2q1fourth", class "guide-question", onClick (UpdateAnswer "Activity2" "Question1" "Answer4") ] []
            , label [ for "a2q1fourth" ] [ getAnswerText model "Activity2" "Question1" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question1", id "a2q1fifth", class "guide-question", onClick (UpdateAnswer "Activity2" "Question1" "Answer5") ] []
            , label [ for "a2q1fifth" ] [ getAnswerText model "Activity2" "Question1" "Answer5" ]
            ]
        , div []
            [ if answerButtonVisible then
                div []
                    [ button [ onClick (RevealSolution "Activity2" "Question1") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct_answer" ]

                             else
                                div [ class "incorrect_answer" ]
                            )
                                [ Html.text "The correct answer is \"adjective\". It describes the noun \"face\""
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewThirdQuestion : Model -> Html Msg
viewThirdQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity2" "Question2"

        answerCorrect =
            checkAnswerCorrect model "Activity2" "Question2"

        solutionVisible =
            checkButtonClicked model "Activity2" "Question2"
    in
    div []
        [ Html.div [] [ text "zarred" ]
        , Html.form []
            [ input [ type_ "radio", name "activity2_question2", id "a2q2first", class "guide-question", onClick (UpdateAnswer "Activity2" "Question2" "Answer1") ] []
            , label [ for "a2q2first" ] [ getAnswerText model "Activity2" "Question2" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question2", id "a2q2second", class "guide-question", onClick (UpdateAnswer "Activity2" "Question2" "Answer2") ] []
            , label [ for "a2q2second" ] [ getAnswerText model "Activity2" "Question2" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question2", id "a2q2third", class "guide-question", onClick (UpdateAnswer "Activity2" "Question2" "Answer3") ] []
            , label [ for "a2q2third" ] [ getAnswerText model "Activity2" "Question2" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question2", id "a2q2fourth", class "guide-question", onClick (UpdateAnswer "Activity2" "Question2" "Answer4") ] []
            , label [ for "a2q2fourth" ] [ getAnswerText model "Activity2" "Question2" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question2", id "a2q2fifth", class "guide-question", onClick (UpdateAnswer "Activity2" "Question2" "Answer5") ] []
            , label [ for "a2q2fifth" ] [ getAnswerText model "Activity2" "Question2" "Answer5" ]
            ]
        , div []
            [ if answerButtonVisible then
                div []
                    [ button [ onClick (RevealSolution "Activity2" "Question2") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct_answer" ]

                             else
                                div [ class "incorrect_answer" ]
                            )
                                [ Html.text "The correct answer is \"verb\". It follows the subject \"the girl\" and makes a complete thought, so it is most likely a verb. It also has the past tense ending (-ed) on it."
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewFourthQuestion : Model -> Html Msg
viewFourthQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity2" "Question3"

        answerCorrect =
            checkAnswerCorrect model "Activity2" "Question3"

        solutionVisible =
            checkButtonClicked model "Activity2" "Question3"
    in
    div []
        [ Html.div [] [ text "paplil" ]
        , Html.form []
            [ input [ type_ "radio", name "activity2_question3", id "a2q3first", class "guide-question", onClick (UpdateAnswer "Activity2" "Question3" "Answer1") ] []
            , label [ for "a2q3first" ] [ getAnswerText model "Activity2" "Question3" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question3", id "a2q3second", class "guide-question", onClick (UpdateAnswer "Activity2" "Question3" "Answer2") ] []
            , label [ for "a2q3second" ] [ getAnswerText model "Activity2" "Question3" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question3", id "a2q3third", class "guide-question", onClick (UpdateAnswer "Activity2" "Question3" "Answer3") ] []
            , label [ for "a2q3third" ] [ getAnswerText model "Activity2" "Question3" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question3", id "a2q3fourth", class "guide-question", onClick (UpdateAnswer "Activity2" "Question3" "Answer4") ] []
            , label [ for "a2q3fourth" ] [ getAnswerText model "Activity2" "Question3" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question3", id "a2q3fifth", class "guide-question", onClick (UpdateAnswer "Activity2" "Question3" "Answer5") ] []
            , label [ for "a2q3fifth" ] [ getAnswerText model "Activity2" "Question3" "Answer5" ]
            ]
        , div []
            [ if answerButtonVisible then
                div []
                    [ button [ onClick (RevealSolution "Activity2" "Question3") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct_answer" ]

                             else
                                div [ class "incorrect_answer" ]
                            )
                                [ Html.text "The correct answer is \"noun\". The word is preceded by the indefinite article \"a\" which strongly suggests a noun."
                                ]

                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewFifthQuestion : Model -> Html Msg
viewFifthQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity2" "Question4"

        answerCorrect =
            checkAnswerCorrect model "Activity2" "Question4"

        solutionVisible =
            checkButtonClicked model "Activity2" "Question4"
    in
    div []
        [ Html.div [] [ text "nagril" ]
        , Html.form []
            [ input [ type_ "radio", name "activity2_question4", id "a2q4first", class "guide-question", onClick (UpdateAnswer "Activity2" "Question4" "Answer1") ] []
            , label [ for "a2q4first" ] [ getAnswerText model "Activity2" "Question4" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question4", id "a2q4second", class "guide-question", onClick (UpdateAnswer "Activity2" "Question4" "Answer2") ] []
            , label [ for "a2q4second" ] [ getAnswerText model "Activity2" "Question4" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question4", id "a2q4third", class "guide-question", onClick (UpdateAnswer "Activity2" "Question4" "Answer3") ] []
            , label [ for "a2q4third" ] [ getAnswerText model "Activity2" "Question4" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question4", id "a2q4fourth", class "guide-question", onClick (UpdateAnswer "Activity2" "Question4" "Answer4") ] []
            , label [ for "a2q4fourth" ] [ getAnswerText model "Activity2" "Question4" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question5", id "a2q4fifth", class "guide-question", onClick (UpdateAnswer "Activity2" "Question4" "Answer5") ] []
            , label [ for "a2q4fifth" ] [ getAnswerText model "Activity2" "Question4" "Answer5" ]
            ]
        , div []
            [ if answerButtonVisible then
                div []
                    [ button [ onClick (RevealSolution "Activity2" "Question4") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct_answer" ]

                             else
                                div [ class "incorrect_answer" ]
                            )
                                [ Html.text "The correct answer is \"adjective\". It is used in an adjective phrase following \"a most...\" and it is also in parallel construction to \"searching\" and so it is being used as some kind of modifier to the noun profar."
                                ]

                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewSixthQuestion : Model -> Html Msg
viewSixthQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity2" "Question5"

        answerCorrect =
            checkAnswerCorrect model "Activity2" "Question5"

        solutionVisible =
            checkButtonClicked model "Activity2" "Question5"
    in
    div []
        [ Html.div [] [ text "sar" ]
        , Html.form []
            [ input [ type_ "radio", name "activity2_question5", id "a2q5first", class "guide-question", onClick (UpdateAnswer "Activity2" "Question5" "Answer1") ] []
            , label [ for "a2q5first" ] [ getAnswerText model "Activity2" "Question5" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question5", id "a2q5second", class "guide-question", onClick (UpdateAnswer "Activity2" "Question5" "Answer2") ] []
            , label [ for "a2q5second" ] [ getAnswerText model "Activity2" "Question5" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question5", id "a2q5third", class "guide-question", onClick (UpdateAnswer "Activity2" "Question5" "Answer3") ] []
            , label [ for "a2q5third" ] [ getAnswerText model "Activity2" "Question5" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question5", id "a2q5fourth", class "guide-question", onClick (UpdateAnswer "Activity2" "Question5" "Answer4") ] []
            , label [ for "a2q5fourth" ] [ getAnswerText model "Activity2" "Question5" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question6", id "a2q5fifth", class "guide-question", onClick (UpdateAnswer "Activity2" "Question5" "Answer5") ] []
            , label [ for "a2q5fifth" ] [ getAnswerText model "Activity2" "Question5" "Answer5" ]
            ]
        , div []
            [ if answerButtonVisible then
                div []
                    [ button [ onClick (RevealSolution "Activity2" "Question5") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct_answer" ]

                             else
                                div [ class "incorrect_answer" ]
                            )
                                [ Html.text """The best answer here is "conjunction" since it connects two clauses "there was no..." and "he looked for something," it must be a conjunction, possibly "though" or "but."""
                                ]

                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewSeventhQuestion : Model -> Html Msg
viewSeventhQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity2" "Question6"

        answerCorrect =
            checkAnswerCorrect model "Activity2" "Question6"

        solutionVisible =
            checkButtonClicked model "Activity2" "Question6"
    in
    div []
        [ Html.div [] [ text "parnly" ]
        , Html.form []
            [ input [ type_ "radio", name "activity2_question6", id "a2q6first", class "guide-question", onClick (UpdateAnswer "Activity2" "Question6" "Answer1") ] []
            , label [ for "a2q6first" ] [ getAnswerText model "Activity2" "Question6" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question6", id "a2q6second", class "guide-question", onClick (UpdateAnswer "Activity2" "Question6" "Answer2") ] []
            , label [ for "a2q6second" ] [ getAnswerText model "Activity2" "Question6" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question6", id "a2q6third", class "guide-question", onClick (UpdateAnswer "Activity2" "Question6" "Answer3") ] []
            , label [ for "a2q6third" ] [ getAnswerText model "Activity2" "Question6" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question6", id "a2q6fourth", class "guide-question", onClick (UpdateAnswer "Activity2" "Question6" "Answer4") ] []
            , label [ for "a2q6fourth" ] [ getAnswerText model "Activity2" "Question6" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question6", id "a2q6fifth", class "guide-question", onClick (UpdateAnswer "Activity2" "Question6" "Answer5") ] []
            , label [ for "a2q6fifth" ] [ getAnswerText model "Activity2" "Question6" "Answer5" ]
            ]
        , div []
            [ if answerButtonVisible then
                div []
                    [ button [ onClick (RevealSolution "Activity2" "Question6") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct_answer" ]

                             else
                                div [ class "incorrect_answer" ]
                            )
                                [ Html.text """The best answer here is "adverb". It must be an adjective or adverb to be used in the phrase "as X as," and the "-ly" suffix suggests an adverb."""
                                ]

                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewEigthQuestion : Model -> Html Msg
viewEigthQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity3" "Question1"

        answerCorrect =
            checkAnswerCorrect model "Activity3" "Question1"

        solutionVisible =
            checkButtonClicked model "Activity3" "Question1"
    in
    div []
        [ Html.div [] [ text "Go back to the text, and locate the place there the author seems to describe the emotions of the characters. Which of these words would be the most important to look up?" ]
        , Html.form []
            [ input [ type_ "radio", name "activity3_question1", id "a3q1first", class "guide-question", onClick (UpdateAnswer "Activity3" "Question1" "Answer1") ] []
            , label [ for "a3q1first" ] [ getAnswerText model "Activity3" "Question1" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question1", id "a3q1second", class "guide-question", onClick (UpdateAnswer "Activity3" "Question1" "Answer2") ] []
            , label [ for "a3q1second" ] [ getAnswerText model "Activity3" "Question1" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question1", id "a3q1third", class "guide-question", onClick (UpdateAnswer "Activity3" "Question1" "Answer3") ] []
            , label [ for "a3q1third" ] [ getAnswerText model "Activity3" "Question1" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question1", id "a3q1fourth", class "guide-question", onClick (UpdateAnswer "Activity3" "Question1" "Answer4") ] []
            , label [ for "a3q1fourth" ] [ getAnswerText model "Activity3" "Question1" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question1", id "a3q1fifth", class "guide-question", onClick (UpdateAnswer "Activity3" "Question1" "Answer5") ] []
            , label [ for "a3q1fifth" ] [ getAnswerText model "Activity3" "Question1" "Answer5" ]
            ]
        , div []
            [ if answerButtonVisible then
                div []
                    [ button [ onClick (RevealSolution "Activity3" "Question1") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct_answer" ]

                             else
                                div [ class "incorrect_answer" ]
                            )
                                [ Html.text """Choices e) bazad and f) fisd would be high priority in determining the emotional charge of this seen, since they both describe the girl's look at the man.
                                Choices b) fornoy and d) calbained are medium priority. Knowing the meaning of "fornoy" might help to clarify the bond/relationship between the man and the girl.
                                Since "calbained" is an action that the man does with his head, it might reveal how the man communicates with the girl.
                                The choice a) foslaint would be lower priority, since it relates primarily to the man in the boat, and "foslaint" is likely to be a word of physical description for the man.
                                The choice c) divey would be lowest priority, since it describes the boat, and is unlikely to give a direct indication of the emotional relationship between the man and the girl."""
                                ]

                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


getAnswerText : Model -> String -> String -> String -> Html Msg
getAnswerText model activityKey questionKey answerKey =
    let
        maybeQuestion =
            case Dict.get activityKey model.activities of
                Just qs ->
                    Dict.get questionKey (questions qs)

                Nothing ->
                    Maybe.map identity Nothing

        maybeAnswer =
            case maybeQuestion of
                Just q ->
                    Dict.get answerKey (answers q)

                Nothing ->
                    Maybe.map identity Nothing

        answerText =
            case maybeAnswer of
                Just a ->
                    a.answer

                Nothing ->
                    ""
    in
    Html.text answerText


checkAnswerCorrect : Model -> String -> String -> Bool
checkAnswerCorrect model activityLabel questionLabel =
    let
        maybeActivity =
            Dict.get activityLabel model.activities

        maybeQuestion =
            case maybeActivity of
                Just ac ->
                    Dict.get questionLabel (questions ac)

                Nothing ->
                    Maybe.map identity Nothing

        answerList =
            case maybeQuestion of
                Just q ->
                    List.map Tuple.second (Dict.toList (answers q))

                Nothing ->
                    []

        answeredCorrectly =
            List.any (\v -> v == True) (List.map (\a -> (a.correct == True) && a.selected) answerList)
    in
    answeredCorrectly


checkAnswerSelected : Model -> String -> String -> Bool
checkAnswerSelected model activityLabel questionLabel =
    let
        maybeActivity =
            Dict.get activityLabel model.activities

        maybeQuestion =
            case maybeActivity of
                Just ac ->
                    Dict.get questionLabel (questions ac)

                Nothing ->
                    Maybe.map identity Nothing

        answerList =
            case maybeQuestion of
                Just q ->
                    List.map Tuple.second (Dict.toList (answers q))

                Nothing ->
                    []

        answerSelected =
            List.any (\a -> a.selected == True) answerList
    in
    answerSelected


checkButtonClicked : Model -> String -> String -> Bool
checkButtonClicked model activityLabel questionLabel =
    let
        maybeActivities =
            Dict.get activityLabel model.activities

        maybeQuestion = case maybeActivities of
            Just activities -> Dict.get questionLabel (questions activities)
            Nothing -> Maybe.map identity Nothing

    in
        case maybeQuestion of 
            Just question -> showSolution question
            Nothing -> False 


viewTabs : Html Msg
viewTabs =
    div [ class "guide-tabs" ]
        [ div
            [ class "guide-tab"
            , class "leftmost-guide-tab"
            ]
            [ a
                [ href (Route.toString Route.Guide__GettingStarted)
                , class "guide-link"
                ]
                [ text "Getting Started" ]
            ]
        , div
            [ class "guide-tab"
            ]
            [ a
                [ href (Route.toString Route.Guide__ReadingTexts)
                , class "guide-link"
                ]
                [ text "Reading Texts" ]
            ]
        , div
            [ class "guide-tab"
            ]
            [ a
                [ href (Route.toString Route.Guide__Settings)
                , class "guide-link"
                ]
                [ text "Settings" ]
            ]
        , div
            [ class "guide-tab"
            ]
            [ a
                [ href (Route.toString Route.Guide__Progress)
                , class "guide-link"
                ]
                [ text "Progress" ]
            ]
        , div
            [ class "guide-tab"
            , class "selected-guide-tab"
            ]
            [ a
                [ href (Route.toString Route.Guide__Strategies)
                , class "guide-link"
                ]
                [ text "Strategies" ]
            ]
        , div
            [ class "guide-tab"
            ]
            [ a
                [ href (Route.toString Route.Guide__Comprehension)
                , class "guide-link"
                ]
                [ text "Comprehension" ]
            ]
        , div
            [ class "guide-tab"
            ]
            [ a
                [ href (Route.toString Route.Guide__Context)
                , class "guide-link"
                ]
                [ text "Context" ]
            ]
        , div
            [ class "guide-tab"
            , class "selected-guide-tab"
            ]
            [ a
                [ href (Route.toString Route.Guide__Priority)
                , class "guide-link"
                ]
                [ text "Priority" ]
            ]
        ]


viewFirstSection : Html Msg
viewFirstSection =
    Markdown.toHtml [ attribute "class" "markdown-link" ] """
### Prioritizing words

It is usually not practical to try to look up every word that you don’t know in a text. It can take far too much time, and the process of looking 
may distract you from trying to get any meaning out of what you do understand. So, you need to develop a sense of what words to prioritize for looking up. 


1. **Notice the frequency of unfamiliar words**
The first thing to prioritize are unknown words that appear multiple times in a text or passage. Understanding repeated words will help you stretch your understanding of the text.
"""


viewSecondSection : Html Msg
viewSecondSection =
    div [ class "sample-passage" ]
        [ Html.em [] [ Html.text "A Boat on the River" ]
        , Html.br [] []
        , Html.br [] []
        , Html.text """
        The gapels in this boat were those of a foslaint man with nabelked amboned hair and a trathmollated face, and a finlact girl of nineteen or twenty, 
        nabbastly like him to be sorbicable as his """
        , Html.strong [] [ Html.text "fornoy" ]
        , Html.text """. The girl zarred, pulling a pair of sculls very easily; the man, with the rudder-lines slack in 
        his dispers, and his dispers loose in his waistband, kept an eager look out. He had no net, galeaft, or line, and he could not be a paplil; his boat 
        had no """
        , Html.strong [] [ Html.text "exbain" ]
        , Html.text """ for a sitter, no paint, no debilk, no bepult beyond a rusty calben and a lanop of rope, and he could not be a waterman; his boat was too 
        anem and too divey to take in besder for delivery, and he could not be a river-carrier; there was no paff to what he looked for, sar he looked for 
        something, with a most nagril and searching profar. The befin, which had turned an hour before, was melucting zopt, and his eyes """
        , Html.strong [] [ Html.text "hasteled" ]
        , Html.text " every little furan and gaist in its broad sweep, as the boat made bilp ducasp against it, or drove stern foremost before it, according as he calbained his "
        , Html.strong [] [ Html.text "fornoy" ]
        , Html.text " by a "
        , Html.strong [] [ Html.text "calput" ]
        , Html.text " of his head. She "
        , Html.strong [] [ Html.text "hasteled" ]
        , Html.text " his face as parnly as he "
        , Html.strong [] [ Html.text "hasteled" ]
        , Html.text " the river. But, in the astortant of her look there was a touch of bazad or fisd."
        ]


viewThirdSection : Html Msg
viewThirdSection =
    Markdown.toHtml [] """
### Prioritize words to look up strategically
What next to prioritize will depend on what your motivation for reading is. If you’re trying to follow the basic plot of a story, then look up nouns and verbs, so you know where, when, 
who and what. If you’re trying to understand a character, then look up adjectives and phrases that are applied to that character. If you are trying to follow motivations of characters, then 
looking up words in the clause that starts with the word “because….” might be most helpful. If you are reading a text for class, the comprehension questions your teacher has assigned can help 
you prioritize what parts of the text you need to focus on.

#### Unfamiliar words and their part of speech
Part of prioritizing what words to look up is recognizing or having a strong sense as to the part of speech of the unfamiliar word. Using the grammar of the surrounding text, you can often 
tell an unfamiliar word’s part of speech. The nonsense words in this text also all use regular English grammatical endings, so those can help you as well. Be sure to determine the part of 
speech based on how the word is used in the sentence and not just on its grammatical ending.
"""


viewFourthSection : Html Msg
viewFourthSection =
    div [ class "sample-passage" ]
        [ Html.em [] [ Html.text "A Boat on the River" ]
        , Html.br [] []
        , Html.br [] []
        , Html.text "The gapels in this boat were those of a foslaint man with nabelked amboned hair and a "
        , Html.strong [] [ Html.text "trathmollated" ]
        , Html.text " face, and a finlact girl of nineteen or twenty, nabbastly like him to be sorbicable as his fornoy. The girl "
        , Html.strong [] [ Html.text "zarred" ]
        , Html.text """, pulling a pair of sculls very easily; the man, with the rudder-lines slack in his dispers, and his dispers loose in his waistband, 
        kept an eager look out. He had no net, galeaft, or line, and he could not be a """
        , Html.strong [] [ Html.text "paplil" ]
        , Html.text """; his boat had no exbain for a sitter, no paint, no debilk, no bepult beyond a rusty calben and a lanop of rope, and he could not be a waterman; his boat was too 
        anem and too divey to take in besder for delivery, and he could not be a river-carrier; there was no paff to what he looked for, """
        , Html.strong [] [ Html.text "sar" ]
        , Html.text " he looked for something, with a most "
        , Html.strong [] [ Html.text "nagril" ]
        , Html.text """ and searching profar. The befin, which had turned an hour before, was melucting zopt, and his eyes hasteled every little 
        furan and gaist in its broad sweep, as the boat made bilp ducasp against it, or drove stern foremost before it, according as he calbained his fornoy by 
        a calput of his head. She hasteled his face as """
        , Html.strong [] [ Html.text "parnly" ]
        , Html.text " as he hasteled the river. But, in the astortant of her look there was a touch of bazad or fisd."
        ]


viewFifthSection : Html Msg
viewFifthSection =
    Markdown.toHtml [] """
### Unfamiliar words and their importance to your tasks

If you are reading a text for class, the comprehension questions your teacher has assigned can help you prioritize what parts of the text you need to focus on. For example, your teacher 
included a question that asked about the emotional relationship between the man and the girl in the boat. You will need to locate the part of the text that contains that information, and to 
prioritize those descriptive words that will help you understand that relationship.
"""


viewSixthSection : Html Msg
viewSixthSection =
    div [ class "sample-passage" ]
        [ Html.em [] [ Html.text "A Boat on the River" ]
        , Html.br [] []
        , Html.br [] []
        , Html.text "The gapels in this boat were those of a "
        , Html.strong [] [ Html.text "foslaint" ]
        , Html.text " man with nabelked amboned hair and a trathmollated face, and a finlact girl of nineteen or twenty, nabbastly like him to be sorbicable as his "
        , Html.strong [] [ Html.text "fornoy" ]
        , Html.text """. The girl zarred, pulling a pair of sculls very easily; the man, with the rudder-lines slack in 
        his dispers, and his dispers loose in his waistband, kept an eager look out. He had no net, galeaft, or line, and he could not be a paplil; his boat 
        had no exbain for a sitter, no paint, no debilk, no bepult beyond a rusty calben and a lanop of rope, and he could not be a waterman; his boat was too 
        anem and too """
        , Html.strong [] [ Html.text "divey" ]
        , Html.text """ to take in besder for delivery, and he could not be a river-carrier; there was no paff to what he looked for, sar he looked for 
        something, with a most nagril and searching profar. The befin, which had turned an hour before, was melucting zopt, and his eyes hasteled every little 
        furan and gaist in its broad sweep, as the boat made bilp ducasp against it, or drove stern foremost before it, according as he """
        , Html.strong [] [ Html.text "calbained" ]
        , Html.text " his "
        , Html.strong [] [ Html.text "fornoy" ]
        , Html.text " by a calput of his head. She hasteled his face as parnly as he hasteled the river. But, in the astortant of her look there was a touch of "
        , Html.strong [] [ Html.text "bazad" ]
        , Html.text " or "
        , Html.strong [] [ Html.text "fisd" ]
        , Html.text "."
        ]


viewSeventhSection : Html Msg
viewSeventhSection =
    Markdown.toHtml [] """
#### When looking up words
Once you’ve prioritized a word for look up, be sure you make a guess about its English equivalent before you actually look it up. If your guess is right (or a very close synonym to the right answer), 
then you are probably understanding the passage well.  If your guess is very far from the right answer, be sure to re-read the passage to understand how that changes your sense of what the passage is 
about. If your guess is very far from the answer you find, check to make certain that the word doesn't have other meanings that might fight the context. There aren't an enormous number of homonyms in 
Russian, but many Russian words can be used in different senses or contexts. Be sure that you've got the right sense for your context.

#### Homonyms
Homonyms to look out for:

есть -- can be an infinitive "to eat," and it can be the third person of the verb быть meaning "there is/there are." 

стали -- can be the past tense of стать = to become, begin OR the genitive/dative/prepositional of the noun сталь = steel

Words that are similar, but have different stress

за́мок - (noun) castle

замо́к - (noun) lock

мука́ - (noun) flour

му́ка - (noun) torment
"""


viewAltText : String -> Dict String String -> String
viewAltText id texts =
    case Dict.get id texts of
        Just text ->
            text

        Nothing ->
            ""


altTexts : Dict String String
altTexts =
    Dict.fromList
        []



-- SHARED


save : Model -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- given an activity question and answer
-- update the model's corresponding activity question answer to indicate it's been selected
-- filter the list of activities to find the activity with a matching label to the one passed to update
-- use `questions` to get the list of questions given an activity,
-- filter on these to find the question matching the question passed to update
-- use `answers` to get the list of answers given a question
-- filter on these to find the answer matching the answer passed to update
-- func is some function which updates the answer's checked field
-- | activities = map func ( List.filter (\v -> v == a) model.activities)-- update one activity.question.answer that has been clicked
-- filter the questions after activities
-- filter answers after questions
-- mark whatever answer as "checked"
-- somewhere needs if "correct" and "checked" -> green feedback
-- else -> red feedback
-- updateActivity : Model -> String -> String -> String -> Model
-- updateActivity model activity question answer =
--     -- case
--     { model | activities = Dict.update activity (Maybe.map (updateQuestion question answer)) model.activities }
-- updateQuestion : String -> String -> Dict String Question -> Dict String Question
-- updateQuestion q a qs =
--     -- Dict.update "question1" (Maybe.map (a function that updates an answer in the dict of answers -> returns the value accessed by the key "answer1")) qs
--     Dict.update q (Maybe.map updateAnswer a) qs
-- updateAnswer : String -> String -> Dict String Answer
-- updateAnswer an ans =
--     -- Dict.update "answer1" (Maybe.map (a function that updates the checked field of the record accessed by "answer1" -> return the value accessed by "answer1")) ans
--     Dict.update an (\a -> Maybe.map updateAnswerCheckedField a) ans
-- updateAnswerCheckedField : Answer -> Answer
-- updateAnswerCheckedField an =
--     { an | selected = not an.selected }
