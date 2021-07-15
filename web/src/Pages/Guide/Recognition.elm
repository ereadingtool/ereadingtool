module Pages.Guide.Recognition exposing (..)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Markdown
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
                            [ ( "Answer1", Answer "адрес" False False )
                            , ( "Answer2", Answer "парк" False False )
                            , ( "Answer3", Answer "проспект" False False )
                            , ( "Answer4", Answer "театр" True False )
                            , ( "Answer5", Answer "музыка" False False )
                            , ( "Answer6", Answer "виза" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                , ( "Question2"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "адрес" True False )
                            , ( "Answer2", Answer "парк" False False )
                            , ( "Answer3", Answer "проспект" False False )
                            , ( "Answer4", Answer "театр" False False )
                            , ( "Answer5", Answer "музыка" False False )
                            , ( "Answer6", Answer "виза" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
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
                            [ ( "Answer1", Answer "реформа" False False )
                            , ( "Answer2", Answer "логика" True False )
                            , ( "Answer3", Answer "фигура" False False )
                            , ( "Answer4", Answer "секунда" False False )
                            , ( "Answer5", Answer "фаза" False False )
                            , ( "Answer6", Answer "поза" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                , ( "Question2"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "реформа" False False )
                            , ( "Answer2", Answer "логика" False False )
                            , ( "Answer3", Answer "фигура" False False )
                            , ( "Answer4", Answer "секунда" True False )
                            , ( "Answer5", Answer "фаза" False False )
                            , ( "Answer6", Answer "поза" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                , ( "Question3"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "реформа" False False )
                            , ( "Answer2", Answer "логика" False False )
                            , ( "Answer3", Answer "фигура" False False )
                            , ( "Answer4", Answer "секунда" False False )
                            , ( "Answer5", Answer "фаза" True False )
                            , ( "Answer6", Answer "поза" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                , ( "Question4"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "реформа" False False )
                            , ( "Answer2", Answer "логика" False False )
                            , ( "Answer3", Answer "фигура" False False )
                            , ( "Answer4", Answer "секунда" False False )
                            , ( "Answer5", Answer "фаза" False False )
                            , ( "Answer6", Answer "поза" True False )
                            ]
                        )
                        { showButton = False, showSolution = False }
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
                            [ ( "Answer1", Answer "элита" False False )
                            , ( "Answer2", Answer "дата" False False )
                            , ( "Answer3", Answer "атака" False False )
                            , ( "Answer4", Answer "техника" False False )
                            , ( "Answer5", Answer "манера" False False )
                            , ( "Answer6", Answer "пауза" True False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                , ( "Question2"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "элита" True False )
                            , ( "Answer2", Answer "дата" False False )
                            , ( "Answer3", Answer "атака" False False )
                            , ( "Answer4", Answer "техника" False False )
                            , ( "Answer5", Answer "манера" False False )
                            , ( "Answer6", Answer "пауза" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                , ( "Question3"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "элита" False False )
                            , ( "Answer2", Answer "дата" True False )
                            , ( "Answer3", Answer "атака" False False )
                            , ( "Answer4", Answer "техника" False False )
                            , ( "Answer5", Answer "манера" False False )
                            , ( "Answer6", Answer "пауза" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                , ( "Question4"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "элита" False False )
                            , ( "Answer2", Answer "дата" False False )
                            , ( "Answer3", Answer "атака" False False )
                            , ( "Answer4", Answer "техника" False False )
                            , ( "Answer5", Answer "манера" True False )
                            , ( "Answer6", Answer "пауза" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                ]
            )
          )
        , ( "Activity4"
          , Activity
            (Dict.fromList
                [ ( "Question1"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "жанр" False False )
                            , ( "Answer2", Answer "сюжет" False False )
                            , ( "Answer3", Answer "этаж" False False )
                            , ( "Answer4", Answer "пляж" True False )
                            , ( "Answer5", Answer "режим" False False )
                            , ( "Answer6", Answer "экипаж" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                , ( "Question2"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "жанр" False False )
                            , ( "Answer2", Answer "сюжет" False False )
                            , ( "Answer3", Answer "этаж" False False )
                            , ( "Answer4", Answer "пляж" False False )
                            , ( "Answer5", Answer "режим" True False )
                            , ( "Answer6", Answer "экипаж" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                , ( "Question3"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "жанр" False False )
                            , ( "Answer2", Answer "сюжет" False False )
                            , ( "Answer3", Answer "этаж" False False )
                            , ( "Answer4", Answer "пляж" False False )
                            , ( "Answer5", Answer "режим" False False )
                            , ( "Answer6", Answer "экипаж" True False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                , ( "Question4"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "жанр" False False )
                            , ( "Answer2", Answer "сюжет" True False )
                            , ( "Answer3", Answer "этаж" False False )
                            , ( "Answer4", Answer "пляж" False False )
                            , ( "Answer5", Answer "режим" False False )
                            , ( "Answer6", Answer "экипаж" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                , ( "Question5"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "жанр" True False )
                            , ( "Answer2", Answer "сюжет" False False )
                            , ( "Answer3", Answer "этаж" False False )
                            , ( "Answer4", Answer "пляж" False False )
                            , ( "Answer5", Answer "режим" False False )
                            , ( "Answer6", Answer "экипаж" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                ]
            )
          )
        , ( "Activity5"
          , Activity
            (Dict.fromList
                [ ( "Question1"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "цикл" False False )
                            , ( "Answer2", Answer "принцип" False False )
                            , ( "Answer3", Answer "рецепт" False False )
                            , ( "Answer4", Answer "цитата" True False )
                            , ( "Answer5", Answer "церемония" False False )
                            , ( "Answer6", Answer "официант" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                , ( "Question2"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "цикл" False False )
                            , ( "Answer2", Answer "принцип" False False )
                            , ( "Answer3", Answer "рецепт" False False )
                            , ( "Answer4", Answer "цитата" False False )
                            , ( "Answer5", Answer "церемония" False False )
                            , ( "Answer6", Answer "официант" True False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                , ( "Question3"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "цикл" True False )
                            , ( "Answer2", Answer "принцип" False False )
                            , ( "Answer3", Answer "рецепт" False False )
                            , ( "Answer4", Answer "цитата" False False )
                            , ( "Answer5", Answer "церемония" False False )
                            , ( "Answer6", Answer "официант" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                , ( "Question4"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "цикл" False False )
                            , ( "Answer2", Answer "принцип" False False )
                            , ( "Answer3", Answer "рецепт" True False )
                            , ( "Answer4", Answer "цитата" False False )
                            , ( "Answer5", Answer "церемония" False False )
                            , ( "Answer6", Answer "официант" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                , ( "Question5"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "цикл" False False )
                            , ( "Answer2", Answer "принцип" True False )
                            , ( "Answer3", Answer "рецепт" False False )
                            , ( "Answer4", Answer "цитата" False False )
                            , ( "Answer5", Answer "церемония" False False )
                            , ( "Answer6", Answer "официант" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                ]
            )
          )
        , ( "Activity6"
          , Activity
            (Dict.fromList
                [ ( "Question1"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "героиня" False False )
                            , ( "Answer2", Answer "гармония" True False )
                            , ( "Answer3", Answer "гипотеза" False False )
                            , ( "Answer4", Answer "алкоголь" False False )
                            , ( "Answer5", Answer "горизонт" False False )
                            , ( "Answer6", Answer "госпиталь" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                , ( "Question2"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "героиня" True False )
                            , ( "Answer2", Answer "гармония" False False )
                            , ( "Answer3", Answer "гипотеза" False False )
                            , ( "Answer4", Answer "алкоголь" False False )
                            , ( "Answer5", Answer "горизонт" False False )
                            , ( "Answer6", Answer "госпиталь" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                , ( "Question3"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "героиня" False False )
                            , ( "Answer2", Answer "гармония" False False )
                            , ( "Answer3", Answer "гипотеза" False False )
                            , ( "Answer4", Answer "алкоголь" False False )
                            , ( "Answer5", Answer "горизонт" False False )
                            , ( "Answer6", Answer "госпиталь" True False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                , ( "Question4"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "героиня" False False )
                            , ( "Answer2", Answer "гармония" False False )
                            , ( "Answer3", Answer "гипотеза" True False )
                            , ( "Answer4", Answer "алкоголь" False False )
                            , ( "Answer5", Answer "горизонт" False False )
                            , ( "Answer6", Answer "госпиталь" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
                  )
                , ( "Question5"
                  , Question
                        (Dict.fromList
                            [ ( "Answer1", Answer "героиня" False False )
                            , ( "Answer2", Answer "гармония" False False )
                            , ( "Answer3", Answer "гипотеза" False False )
                            , ( "Answer4", Answer "алкоголь" False False )
                            , ( "Answer5", Answer "горизонт" True False )
                            , ( "Answer6", Answer "госпиталь" False False )
                            ]
                        )
                        { showButton = False, showSolution = False }
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
                updatedActivities = accessActivity model activity
                    |> accessQuestion question
                    |> updateQuestionShowsSolution
                    |> updateActivity model activity question
                    |> updateActivities model activity
            in
            ( { model | activities = updatedActivities }, Cmd.none )



-- UPDATE UTILITY


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
    { title = "Guide | Recognition"
    , body =
        [ div [ id "body" ]
            [ div [ id "about" ]
                [ div [ id "about-box" ]
                    [ div [ id "title" ] [ text "Recognition" ]
                        , viewTabs
                        , viewFirstSection
                        , viewInstructionsFirstActivity
                        , viewFirstQuestion model
                        , viewSecondQuestion model
                        , viewNoteFirstActivity
                        , viewSecondSection
                        , viewThirdSection
                        , viewInstructionsSecondActivity
                        , viewThirdQuestion model
                        , viewFourthQuestion model
                        , viewFifthQuestion model
                        , viewSixthQuestion model
                        , viewNoteSecondActivity
                        , viewInstructionsThirdActivity
                        , viewSeventhQuestion model
                        , viewEigthQuestion model
                        , viewNinthQuestion model
                        , viewTenthQuestion model
                        , viewFourthSection
                        , viewInstructionsFourthActivity
                        , viewEleventhQuestion model
                        , viewTwelfthQuestion model
                        , viewThirteenthQuestion model
                        , viewFourteenthQuestion model
                        , viewFifteenthQuestion model
                        , viewSixteenthQuestion model
                        , viewSeventeenthQuestion model
                        , viewEighteenthQuestion model
                        , viewNineteenthQuestion model
                        , viewTwentiethQuestion model
                        , viewSixthSection
                        , viewInstructionsSixthActivity
                        , viewTwentyFirstQuestion model
                        , viewTwentySecondQuestion model
                        , viewTwentyThirdQuestion model
                        , viewTwentyFourthQuestion model
                        , viewTwentyFifthQuestion model
                        , viewSeventhSection
                        , viewEigthSection
                    ]
                ]
            ]
        ]
    }


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
            ]
            [ a
                [ href (Route.toString Route.Guide__Priority)
                , class "guide-link"
                ]
                [ text "Priority" ]
            ]
        , div
            [ class "guide-tab"
            , class "selected-guide-tab"
            ]
            [ a
                [ href (Route.toString Route.Guide__Recognition)
                , class "guide-link"
                ]
                [ text "Recognition" ]
            ]
        ]


viewFirstSection : Html Msg
viewFirstSection =
    Markdown.toHtml [ attribute "class" "markdown-link" ] """
### Word recognition strategies for beginners

#### International words

As you start to learn Russian, one of the most important advantages that you have is that Russian has borrowed many words from English, 
French and German. There will be many words in Russian whose meanings you should be able to guess easily when you sound out these words of 
international origin.  Try the examples below.
"""


viewInstructionsFirstActivity : Html Msg
viewInstructionsFirstActivity = 
    Markdown.toHtml [ attribute "class" "markdown-link" ] """
#### Activity 1

Recognizing international words.

#### Instructions

Sound out the six Russian words on the line below. Decide which of them fit the meanings.

адрес парк проспект театр музыка виза
"""


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
    div [ class "guide-question" ]
        [ Html.div [] [ text "Which one is a place to see a dramatic performance?" ]
        , Html.form []
            [ input [ type_ "radio", name "activity1_question1", id "a1q1first", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question1" "Answer1") ] []
            , label [ for "a1q1first" ] [ getAnswerText model "Activity1" "Question1" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question1", id "a1q1second", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question1" "Answer2") ] []
            , label [ for "a1q1second" ] [ getAnswerText model "Activity1" "Question1" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question1", id "a1q1third", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question1" "Answer3") ] []
            , label [ for "a1q1third" ] [ getAnswerText model "Activity1" "Question1" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question1", id "a1q1fourth", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question1" "Answer4") ] []
            , label [ for "a1q1fourth" ] [ getAnswerText model "Activity1" "Question1" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question1", id "a1q1fifth", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question1" "Answer5") ] []
            , label [ for "a1q1fifth" ] [ getAnswerText model "Activity1" "Question1" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question1", id "a1q1sixth", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question1" "Answer6") ] []
            , label [ for "a1q1sixth" ] [ getAnswerText model "Activity1" "Question1" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity1" "Question1") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text "The correct answer is: театр = theater"
                                , Html.br [] []
                                , Html.text """International words that begin with th in English often as spelled just with т in Russian. """
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
            checkAnswerSelected model "Activity1" "Question2"

        answerCorrect =
            checkAnswerCorrect model "Activity1" "Question2"

        solutionVisible =
            checkButtonClicked model "Activity1" "Question2"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "Which one identifies where a person lives?" ]
        , Html.form []
            [ input [ type_ "radio", name "activity1_question2", id "a1q2first", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question2" "Answer1") ] []
            , label [ for "a1q2first" ] [ getAnswerText model "Activity1" "Question2" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question2", id "a1q2second", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question2" "Answer2") ] []
            , label [ for "a1q2second" ] [ getAnswerText model "Activity1" "Question2" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question2", id "a1q2third", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question2" "Answer3") ] []
            , label [ for "a1q2third" ] [ getAnswerText model "Activity1" "Question2" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question2", id "a1q2fourth", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question2" "Answer4") ] []
            , label [ for "a1q2fourth" ] [ getAnswerText model "Activity1" "Question2" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question2", id "a1q2fifth", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question2" "Answer5") ] []
            , label [ for "a1q2fifth" ] [ getAnswerText model "Activity1" "Question2" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question2", id "a1q2sixth", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question2" "Answer6") ] []
            , label [ for "a1q2sixth" ] [ getAnswerText model "Activity1" "Question2" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity1" "Question2") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text "The correct answer is: адрес = address"
                                , Html.br [] []
                                , Markdown.toHtml [ attribute "class" "markdown-link" ] """
International words will sometimes have modified spelling in Russian. Double-letters which make a single sound are often spelled with a single letter in Russian. The opposite 
is also true: single letters in English that make a double sound are spelled with two letters in Russian. For example, English **x**, making the sounds "k - s," is spelled in 
Russian as **кс** or **кз**. You can see this in the Russian words **ксерокс** = xerox, where the name brand in Russian became the word for a duplicate produced on a copy machine, and 
**экзамен** = examination, an end-of-term test.
                                """
                                ]

                                -- [ Html.text "The correct answer is: адрес = address"
                                -- , Html.br [] []
                                -- , Html.text """International words will sometimes have modified spelling in Russian. Double-letters which make a single sound are often spelled 
                                -- with a single letter in Russian. The opposite is also true: single letters in English that make a double sound are spelled with two letters in Russian. 
                                -- For example, English """
                                -- , Html.strong [] [ text "x" ]
                                -- , Html.text """, making the sounds "k - s," is spelled in Russian as """
                                -- , Html.strong [] [ text "кс" ]
                                -- , Html.text " or "
                                -- , Html.strong [] [ text "кз" ]
                                -- , Html.text ". You can see this in the Russian words "
                                -- , Html.strong [] [ text "ксерокс" ]
                                -- , Html.text " = xerox, where the name brand in Russian became the word for a duplicate produced on a copy machine, and "
                                -- , Html.strong [] [ text "экзамен" ]
                                -- , Html.text " = examination, an end-of-term test."
                                -- ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewNoteFirstActivity : Html Msg
viewNoteFirstActivity = 
    Markdown.toHtml [ attribute "class" "markdown-link" ] """
**Note:** You should still use context to verify what exact sense the word has, but the words should be easily recognized. For example парк means "park" in the sense of a place for recreation, and not something you do with a car. 
"""


viewSecondSection : Html Msg
viewSecondSection =
    Markdown.toHtml [ attribute "class" "markdown-link" ] """
### International words with modifications

Sometimes, international words will get a small modification so that they fit more easily into Russian's grammatical system.

For example, many international words for nouns may acquire a feminine ending in -а or -я.  This ending shouldn't keep you from uncovering the basic meaning of the word.

Many international words borrowed into Russian may have a narrower or slightly different range of meanings than the words may have in English.  Consider context as you try to identify the specific meaning that an international word has in Russian.
"""

viewThirdSection : Html Msg
viewThirdSection =
    div []
        [ table [] <|
            [ caption [] [ text "International words in Russian with -а /-я" ]
            , tr []
                [ th [] [ text "Russian word" ]
                , th [] [ text "English" ]
                , th [] [ text "Comments" ]
                ]
            , tr []
                [ td [] [ text "проблема" ]
                , td [] [ text "problem" ]
                , td [] [ text "An international word of Greek origin where it ended in -a, so Russian adopted it as a feminine noun (although it was neuter in Greek.)" ]
                ]
            , tr []
                [ td [] [ text "система" ]
                , td [] [ text "system" ]
                , td [] [ Markdown.toHtml [ attribute "class" "markdown-link" ] """Note that Russian **и** often stands in for **y** in words of Greek origin. """]
                ]
            , tr []
                [ td [] [ text "группа" ]
                , td [] [ text "group" ]
                , td [] [ text "Some international words do retain double consonants."]
                ]
            , tr [] 
                [ td [] [ text "фирма" ]
                , td [] [ text "firm" ]
                , td [] [ Markdown.toHtml [ attribute "class" "markdown-link" ] """As in a company or a business, where originally a transaction was firmed up, or confirmed 
                by a signature. International words from Latin often have an **ф** in Russian, where English will have **f**."""]]
            , tr []
                [ td [] [ text "катастрофа" ]
                , td [] [ text "catastrophe" ]
                , td [] [ Markdown.toHtml [ attribute "class" "markdown-link" ] """International words borrowed from Greek, often have an <strong>ф</strong> in Russian, where English will have <strong>ph</strong>."""]
                ]
            , tr []
                [ td [] [ text "схема" ]
                , td [] [ text "scheme" ]
                , td [] [ Markdown.toHtml [ attribute "class" "markdown-link" ] """As in a schematic drawing. International words borrowed from Greek, often have an **х** in Russian, where English will have **ch**."""]
                ]
            ]
        ]


viewInstructionsSecondActivity : Html Msg
viewInstructionsSecondActivity = 
    Markdown.toHtml [ attribute "class" "markdown-link" ] """
#### Activity 2 

Recognizing international words.

#### Instructions

Sound out the six Russian words on the line below. Decide which of them fit the meanings.

реформа логика фигура секунда фаза поза
"""


viewThirdQuestion : Model -> Html Msg
viewThirdQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity2" "Question1"

        answerCorrect =
            checkAnswerCorrect model "Activity2" "Question1"

        solutionVisible =
            checkButtonClicked model "Activity2" "Question1"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "Which would you apply to solve a hard problem?" ]
        , Html.form []
            [ input [ type_ "radio", name "activity2_question1", id "a2q1first", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question1" "Answer1") ] []
            , label [ for "a2q1first" ] [ getAnswerText model "Activity2" "Question1" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question1", id "a2q1second", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question1" "Answer2") ] []
            , label [ for "a2q1second" ] [ getAnswerText model "Activity2" "Question1" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question1", id "a2q1third", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question1" "Answer3") ] []
            , label [ for "a2q1third" ] [ getAnswerText model "Activity2" "Question1" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question1", id "a2q1fourth", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question1" "Answer4") ] []
            , label [ for "a2q1fourth" ] [ getAnswerText model "Activity2" "Question1" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question1", id "a2q1fifth", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question1" "Answer5") ] []
            , label [ for "a2q1fifth" ] [ getAnswerText model "Activity2" "Question1" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question1", id "a2q1sixth", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question1" "Answer6") ] []
            , label [ for "a2q1sixth" ] [ getAnswerText model "Activity2" "Question1" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity2" "Question1") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text "The correct answer is: логика = logic "
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
            checkAnswerSelected model "Activity2" "Question2"

        answerCorrect =
            checkAnswerCorrect model "Activity2" "Question2"

        solutionVisible =
            checkButtonClicked model "Activity2" "Question2"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "Which is the subdivision of a minute?" ]
        , Html.form []
            [ input [ type_ "radio", name "activity2_question2", id "a2q2first", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question2" "Answer1") ] []
            , label [ for "a2q2first" ] [ getAnswerText model "Activity2" "Question2" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question2", id "a2q2second", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question2" "Answer2") ] []
            , label [ for "a2q2second" ] [ getAnswerText model "Activity2" "Question2" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question2", id "a2q2third", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question2" "Answer3") ] []
            , label [ for "a2q2third" ] [ getAnswerText model "Activity2" "Question2" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question2", id "a2q2fourth", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question2" "Answer4") ] []
            , label [ for "a2q2fourth" ] [ getAnswerText model "Activity2" "Question2" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question2", id "a2q2fifth", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question2" "Answer5") ] []
            , label [ for "a2q2fifth" ] [ getAnswerText model "Activity2" "Question2" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question2", id "a2q2sixth", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question2" "Answer6") ] []
            , label [ for "a2q2sixth" ] [ getAnswerText model "Activity2" "Question2" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity2" "Question2") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text "The correct answer is: секунда = second "
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
            checkAnswerSelected model "Activity2" "Question3"

        answerCorrect =
            checkAnswerCorrect model "Activity2" "Question3"

        solutionVisible =
            checkButtonClicked model "Activity2" "Question3"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "Which might describe a step or stage of a process?" ]
        , Html.form []
            [ input [ type_ "radio", name "activity2_question3", id "a2q3first", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question3" "Answer1") ] []
            , label [ for "a2q3first" ] [ getAnswerText model "Activity2" "Question3" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question3", id "a2q3second", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question3" "Answer2") ] []
            , label [ for "a2q3second" ] [ getAnswerText model "Activity2" "Question3" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question3", id "a2q3third", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question3" "Answer3") ] []
            , label [ for "a2q3third" ] [ getAnswerText model "Activity2" "Question3" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question3", id "a2q3fourth", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question3" "Answer4") ] []
            , label [ for "a2q3fourth" ] [ getAnswerText model "Activity2" "Question3" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question3", id "a2q3fifth", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question3" "Answer5") ] []
            , label [ for "a2q3fifth" ] [ getAnswerText model "Activity2" "Question3" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question3", id "a2q3sixth", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question3" "Answer6") ] []
            , label [ for "a2q3sixth" ] [ getAnswerText model "Activity2" "Question3" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity2" "Question3") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text "The correct answer is: фаза = phase "
                                , Html.br [] []
                                , Markdown.toHtml [ attribute "class" "markdown-link" ] """This is an international word of Greek origin, where the Russian **ф** corresponds 
                                with English **ph**. Once your eye is trained to this, you should have no trouble seeing that **сфера** is **sphere** and **атмосфера** is **atmosphere**. """
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
            checkAnswerSelected model "Activity2" "Question4"

        answerCorrect =
            checkAnswerCorrect model "Activity2" "Question4"

        solutionVisible =
            checkButtonClicked model "Activity2" "Question4"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "What a model might strike for an art class?" ]
        , Html.form []
            [ input [ type_ "radio", name "activity2_question4", id "a2q4first", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question4" "Answer1") ] []
            , label [ for "a2q4first" ] [ getAnswerText model "Activity2" "Question4" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question4", id "a2q4second", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question4" "Answer2") ] []
            , label [ for "a2q4second" ] [ getAnswerText model "Activity2" "Question4" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question4", id "a2q4third", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question4" "Answer3") ] []
            , label [ for "a2q4third" ] [ getAnswerText model "Activity2" "Question4" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question4", id "a2q4fourth", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question4" "Answer4") ] []
            , label [ for "a2q4fourth" ] [ getAnswerText model "Activity2" "Question4" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question4", id "a2q4fifth", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question4" "Answer5") ] []
            , label [ for "a2q4fifth" ] [ getAnswerText model "Activity2" "Question4" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity2_question4", id "a2q4sixth", class "guide-question-button", onClick (UpdateAnswer "Activity2" "Question4" "Answer6") ] []
            , label [ for "a2q4sixth" ] [ getAnswerText model "Activity2" "Question4" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity2" "Question4") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text "The correct answer is: поза = pose "
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]



viewNoteSecondActivity : Html Msg
viewNoteSecondActivity = 
    Markdown.toHtml [ attribute "class" "markdown-link" ] """
**Note:** You should still use context to verify what exact sense the word has, but the words should be easily recognized. 
"""


viewInstructionsThirdActivity : Html Msg
viewInstructionsThirdActivity = 
    Markdown.toHtml [ attribute "class" "markdown-link" ] """
#### Activity 3

Recognizing harder international words.

#### Instructions

Sound out the six Russian words on the line below. Decide which of them fit the meanings.

элита дата атака техника манера пауза
"""


viewSeventhQuestion : Model -> Html Msg
viewSeventhQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity3" "Question1"

        answerCorrect =
            checkAnswerCorrect model "Activity3" "Question1"

        solutionVisible =
            checkButtonClicked model "Activity3" "Question1"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "Which would you want to take between difficult tasks?" ]
        , Html.form []
            [ input [ type_ "radio", name "activity3_question1", id "a3q1first", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question1" "Answer1") ] []
            , label [ for "a3q1first" ] [ getAnswerText model "Activity3" "Question1" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question1", id "a3q1second", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question1" "Answer2") ] []
            , label [ for "a3q1second" ] [ getAnswerText model "Activity3" "Question1" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question1", id "a3q1third", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question1" "Answer3") ] []
            , label [ for "a3q1third" ] [ getAnswerText model "Activity3" "Question1" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question1", id "a3q1fourth", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question1" "Answer4") ] []
            , label [ for "a3q1fourth" ] [ getAnswerText model "Activity3" "Question1" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question1", id "a3q1fifth", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question1" "Answer5") ] []
            , label [ for "a3q1fifth" ] [ getAnswerText model "Activity3" "Question1" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question1", id "a3q1sixth", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question1" "Answer6") ] []
            , label [ for "a3q1sixth" ] [ getAnswerText model "Activity3" "Question1" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity3" "Question1") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text "The correct answer is: пауза = pause "
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
            checkAnswerSelected model "Activity3" "Question2"

        answerCorrect =
            checkAnswerCorrect model "Activity3" "Question2"

        solutionVisible =
            checkButtonClicked model "Activity3" "Question2"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "Select, advantaged group in a society" ]
        , Html.form []
            [ input [ type_ "radio", name "activity3_question2", id "a3q2first", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question2" "Answer1") ] []
            , label [ for "a3q2first" ] [ getAnswerText model "Activity3" "Question2" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question2", id "a3q2second", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question2" "Answer2") ] []
            , label [ for "a3q2second" ] [ getAnswerText model "Activity3" "Question2" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question2", id "a3q2third", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question2" "Answer3") ] []
            , label [ for "a3q2third" ] [ getAnswerText model "Activity3" "Question2" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question2", id "a3q2fourth", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question2" "Answer4") ] []
            , label [ for "a3q2fourth" ] [ getAnswerText model "Activity3" "Question2" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question2", id "a3q2fifth", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question2" "Answer5") ] []
            , label [ for "a3q2fifth" ] [ getAnswerText model "Activity3" "Question2" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question2", id "a3q2sixth", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question2" "Answer6") ] []
            , label [ for "a3q2sixth" ] [ getAnswerText model "Activity3" "Question2" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity3" "Question2") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text "The correct answer is: элита = elite "
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewNinthQuestion : Model -> Html Msg
viewNinthQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity3" "Question3"

        answerCorrect =
            checkAnswerCorrect model "Activity3" "Question3"

        solutionVisible =
            checkButtonClicked model "Activity3" "Question3"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "The day when something happened" ]
        , Html.form []
            [ input [ type_ "radio", name "activity3_question3", id "a3q3first", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question3" "Answer1") ] []
            , label [ for "a3q3first" ] [ getAnswerText model "Activity3" "Question3" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question3", id "a3q3second", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question3" "Answer2") ] []
            , label [ for "a3q3second" ] [ getAnswerText model "Activity3" "Question3" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question3", id "a3q3third", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question3" "Answer3") ] []
            , label [ for "a3q3third" ] [ getAnswerText model "Activity3" "Question3" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question3", id "a3q3fourth", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question3" "Answer4") ] []
            , label [ for "a3q3fourth" ] [ getAnswerText model "Activity3" "Question3" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question3", id "a3q3fifth", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question3" "Answer5") ] []
            , label [ for "a3q3fifth" ] [ getAnswerText model "Activity3" "Question3" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question3", id "a3q3sixth", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question3" "Answer6") ] []
            , label [ for "a3q3sixth" ] [ getAnswerText model "Activity3" "Question3" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity3" "Question3") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text "The correct answer is: дата = date "
                                , Html.br [] []
                                , Markdown.toHtml [ attribute "class" "markdown-link" ] """Дата only refers to the calendar in Russian, a much narrower range of meaning that the 
                                English "date" (which can be a romantic partner, a social event, or even a fruit). Also note that the English word **data** is **данные** in Russian. """
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewTenthQuestion : Model -> Html Msg
viewTenthQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity3" "Question4"

        answerCorrect =
            checkAnswerCorrect model "Activity3" "Question4"

        solutionVisible =
            checkButtonClicked model "Activity3" "Question4"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "Way of behaving in society" ]
        , Html.form []
            [ input [ type_ "radio", name "activity3_question4", id "a3q4first", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question4" "Answer1") ] []
            , label [ for "a3q4first" ] [ getAnswerText model "Activity3" "Question4" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question4", id "a3q4second", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question4" "Answer2") ] []
            , label [ for "a3q4second" ] [ getAnswerText model "Activity3" "Question4" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question4", id "a3q4third", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question4" "Answer3") ] []
            , label [ for "a3q4third" ] [ getAnswerText model "Activity3" "Question4" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question4", id "a3q4fourth", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question4" "Answer4") ] []
            , label [ for "a3q4fourth" ] [ getAnswerText model "Activity3" "Question4" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question4", id "a3q4fifth", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question4" "Answer5") ] []
            , label [ for "a3q4fifth" ] [ getAnswerText model "Activity3" "Question4" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity3_question4", id "a3q4sixth", class "guide-question-button", onClick (UpdateAnswer "Activity3" "Question4" "Answer6") ] []
            , label [ for "a3q4sixth" ] [ getAnswerText model "Activity3" "Question4" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity3" "Question4") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text "The correct answer is: манера = manner "
                                , Html.br [] []
                                , Markdown.toHtml [ attribute "class" "markdown-link" ] """Манера has a much more limited range of use in Russian than the English manner. The 
                                Russian манера is used only about external ways of behaving or acting. The Russian equivalents of "a manner of speaking," "in what manner" and other phrases won't use the word манера. """
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewFourthSection : Html Msg
viewFourthSection =
    Markdown.toHtml [ attribute "class" "markdown-link" ] """
#### International words in Russian with letter ж

Other times, international words came into Russian from French and German and their Russian spelling reflects how the words sounded to Russians 
in the original languages. You might need to think a bit about those sounds and how they are reflected in spelling when you try to guess these words.

#### Spelling the soft "g" sound

For example, many Russian words with **ж** were borrowed from French where those words contained a **soft g** sound, spelled as **-gi-** or **-ge-** or **-j-**.  Some of these French words are also used in English, others are only shared between French and Russian.
"""


viewInstructionsFourthActivity : Html Msg
viewInstructionsFourthActivity =
    Markdown.toHtml [ attribute "class" "markdown-link" ] """
#### Activity 4

Recognizing international words of French origin with letter ж.

#### Instructions

Sound out the six Russian words on the line below. Decide which of them fit the meanings.

жанр сюжет этаж пляж режим экипаж
"""


viewEleventhQuestion : Model -> Html Msg
viewEleventhQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity4" "Question1"

        answerCorrect =
            checkAnswerCorrect model "Activity4" "Question1"

        solutionVisible =
            checkButtonClicked model "Activity4" "Question1"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "The beach" ]
        , Html.form []
            [ input [ type_ "radio", name "activity4_question1", id "a4q1first", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question1" "Answer1") ] []
            , label [ for "a4q1first" ] [ getAnswerText model "Activity4" "Question1" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question1", id "a4q1second", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question1" "Answer2") ] []
            , label [ for "a4q1second" ] [ getAnswerText model "Activity4" "Question1" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question1", id "a4q1third", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question1" "Answer3") ] []
            , label [ for "a4q1third" ] [ getAnswerText model "Activity4" "Question1" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question1", id "a4q1fourth", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question1" "Answer4") ] []
            , label [ for "a4q1fourth" ] [ getAnswerText model "Activity4" "Question1" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question1", id "a4q1fifth", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question1" "Answer5") ] []
            , label [ for "a4q1fifth" ] [ getAnswerText model "Activity4" "Question1" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question1", id "a4q1sixth", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question1" "Answer6") ] []
            , label [ for "a4q1sixth" ] [ getAnswerText model "Activity4" "Question1" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity4" "Question1") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text "The correct answer is: пляж = beach, from French plage."
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewTwelfthQuestion : Model -> Html Msg
viewTwelfthQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity4" "Question2"

        answerCorrect =
            checkAnswerCorrect model "Activity4" "Question2"

        solutionVisible =
            checkButtonClicked model "Activity4" "Question2"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "Political system ruling a country" ]
        , Html.form []
            [ input [ type_ "radio", name "activity4_question2", id "a4q2first", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question2" "Answer1") ] []
            , label [ for "a4q2first" ] [ getAnswerText model "Activity4" "Question2" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question2", id "a4q2second", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question2" "Answer2") ] []
            , label [ for "a4q2second" ] [ getAnswerText model "Activity4" "Question2" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question2", id "a4q2third", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question2" "Answer3") ] []
            , label [ for "a4q2third" ] [ getAnswerText model "Activity4" "Question2" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question2", id "a4q2fourth", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question2" "Answer4") ] []
            , label [ for "a4q2fourth" ] [ getAnswerText model "Activity4" "Question2" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question2", id "a4q2fifth", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question2" "Answer5") ] []
            , label [ for "a4q2fifth" ] [ getAnswerText model "Activity4" "Question2" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question2", id "a4q2sixth", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question2" "Answer6") ] []
            , label [ for "a4q2sixth" ] [ getAnswerText model "Activity4" "Question2" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity4" "Question2") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text "The correct answer is: режим = regime"
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewThirteenthQuestion : Model -> Html Msg
viewThirteenthQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity4" "Question3"

        answerCorrect =
            checkAnswerCorrect model "Activity4" "Question3"

        solutionVisible =
            checkButtonClicked model "Activity4" "Question3"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "The crew of an aircraft or ship" ]
        , Html.form []
            [ input [ type_ "radio", name "activity4_question3", id "a4q3first", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question3" "Answer1") ] []
            , label [ for "a4q3first" ] [ getAnswerText model "Activity4" "Question3" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question3", id "a4q3second", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question3" "Answer2") ] []
            , label [ for "a4q3second" ] [ getAnswerText model "Activity4" "Question3" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question3", id "a4q3third", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question3" "Answer3") ] []
            , label [ for "a4q3third" ] [ getAnswerText model "Activity4" "Question3" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question3", id "a4q3fourth", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question3" "Answer4") ] []
            , label [ for "a4q3fourth" ] [ getAnswerText model "Activity4" "Question3" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question3", id "a4q3fifth", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question3" "Answer5") ] []
            , label [ for "a4q3fifth" ] [ getAnswerText model "Activity4" "Question3" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question3", id "a4q3sixth", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question3" "Answer6") ] []
            , label [ for "a4q3sixth" ] [ getAnswerText model "Activity4" "Question3" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity4" "Question3") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text "The correct answer is: экипаж = crew, although the French équipage starts out with the meaning of a carriage, and then comes to mean the whole team-- carriage, plus horses, plus driver."
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewFourteenthQuestion : Model -> Html Msg
viewFourteenthQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity4" "Question4"

        answerCorrect =
            checkAnswerCorrect model "Activity4" "Question4"

        solutionVisible =
            checkButtonClicked model "Activity4" "Question4"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "The plot of a novel or work of literature" ]
        , Html.form []
            [ input [ type_ "radio", name "activity4_question4", id "a4q4first", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question4" "Answer1") ] []
            , label [ for "a4q4first" ] [ getAnswerText model "Activity4" "Question4" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question4", id "a4q4second", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question4" "Answer2") ] []
            , label [ for "a4q4second" ] [ getAnswerText model "Activity4" "Question4" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question4", id "a4q4third", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question4" "Answer3") ] []
            , label [ for "a4q4third" ] [ getAnswerText model "Activity4" "Question4" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question4", id "a4q4fourth", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question4" "Answer4") ] []
            , label [ for "a4q4fourth" ] [ getAnswerText model "Activity4" "Question4" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question4", id "a4q4fifth", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question4" "Answer5") ] []
            , label [ for "a4q4fifth" ] [ getAnswerText model "Activity4" "Question4" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question4", id "a4q4sixth", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question4" "Answer6") ] []
            , label [ for "a4q4sixth" ] [ getAnswerText model "Activity4" "Question4" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity4" "Question4") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text "The correct answer is: сюжет = plot, story line"
                                , Html.br [] []
                                , Markdown.toHtml [ attribute "class" "markdown-link" ] """The French **sujet** is related to English **subject**, as much as the plot is the subject matter of a work of literature."""
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewFifteenthQuestion : Model -> Html Msg
viewFifteenthQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity4" "Question5"

        answerCorrect =
            checkAnswerCorrect model "Activity4" "Question5"

        solutionVisible =
            checkButtonClicked model "Activity4" "Question5"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "Types of writing, literature (e.g., essay, detective fiction, romance, lyric poetry, etc.)" ]
        , Html.form []
            [ input [ type_ "radio", name "activity4_question5", id "a4q5first", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question5" "Answer1") ] []
            , label [ for "a4q5first" ] [ getAnswerText model "Activity4" "Question5" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question5", id "a4q5second", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question5" "Answer2") ] []
            , label [ for "a4q5second" ] [ getAnswerText model "Activity4" "Question5" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question5", id "a4q5third", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question5" "Answer3") ] []
            , label [ for "a4q5third" ] [ getAnswerText model "Activity4" "Question5" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question5", id "a4q5fourth", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question5" "Answer4") ] []
            , label [ for "a4q5fourth" ] [ getAnswerText model "Activity4" "Question5" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question5", id "a4q5fifth", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question5" "Answer5") ] []
            , label [ for "a4q5fifth" ] [ getAnswerText model "Activity4" "Question5" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity4_question5", id "a4q5sixth", class "guide-question-button", onClick (UpdateAnswer "Activity4" "Question5" "Answer6") ] []
            , label [ for "a4q5sixth" ] [ getAnswerText model "Activity4" "Question5" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity4" "Question5") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text "The correct answer is: жанр = genre"
                                , Html.br [] []
                                , Markdown.toHtml [ attribute "class" "markdown-link" ] """The French **genre** is also used in English. Both originate in the Latin word **genus** meaning "type."

                                The final word in this set **этаж** comes from the French **étage**, meaning "floor" (i.e., level of a building). It is related to the English word **stage**. """
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewFifthSection : Html Msg
viewFifthSection =
    Markdown.toHtml [ attribute "class" "markdown-link" ] """
#### International words in Russian with letter ц

When international words came into Russian from Latin, the Latin letter **c**, when followed by **e** or **i**, was often expressed by **ц** in Russian. In English the **c** in these Latin-based words is usually pronounced as "**s**." The Russian word **концерт** is easily recognized as the English "**concert**" and "**concerto**," and the Russian **офицер** is easily recognized as "**officer**." 
"""


viewInstructionsFifthActivity : Html Msg
viewInstructionsFifthActivity =
    Markdown.toHtml [ attribute "class" "markdown-link" ] """
#### Activity 5

Recognizing international words featuring the letter ц in Russian.

#### Instructions

Sound out the six Russian words on the line below. Decide which of them fit the meanings.

цикл принцип рецепт цитата церемония официант
"""


viewSixteenthQuestion : Model -> Html Msg
viewSixteenthQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity5" "Question1"

        answerCorrect =
            checkAnswerCorrect model "Activity5" "Question1"

        solutionVisible =
            checkButtonClicked model "Activity5" "Question1"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "Words taken from one source and cited in another" ]
        , Html.form []
            [ input [ type_ "radio", name "activity5_question1", id "a5q1first", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question1" "Answer1") ] []
            , label [ for "a5q1first" ] [ getAnswerText model "Activity5" "Question1" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question1", id "a5q1second", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question1" "Answer2") ] []
            , label [ for "a5q1second" ] [ getAnswerText model "Activity5" "Question1" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question1", id "a5q1third", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question1" "Answer3") ] []
            , label [ for "a5q1third" ] [ getAnswerText model "Activity5" "Question1" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question1", id "a5q1fourth", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question1" "Answer4") ] []
            , label [ for "a5q1fourth" ] [ getAnswerText model "Activity5" "Question1" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question1", id "a5q1fifth", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question1" "Answer5") ] []
            , label [ for "a5q1fifth" ] [ getAnswerText model "Activity5" "Question1" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question1", id "a5q1sixth", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question1" "Answer6") ] []
            , label [ for "a5q1sixth" ] [ getAnswerText model "Activity5" "Question1" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity5" "Question1") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text "The correct answer is: цитата = quotation, think about citation."
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]

viewSeventeenthQuestion : Model -> Html Msg
viewSeventeenthQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity5" "Question2"

        answerCorrect =
            checkAnswerCorrect model "Activity5" "Question2"

        solutionVisible =
            checkButtonClicked model "Activity5" "Question2"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "Person serving in a restaurant" ]
        , Html.form []
            [ input [ type_ "radio", name "activity5_question2", id "a5q2first", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question2" "Answer1") ] []
            , label [ for "a5q2first" ] [ getAnswerText model "Activity5" "Question2" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question2", id "a5q2second", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question2" "Answer2") ] []
            , label [ for "a5q2second" ] [ getAnswerText model "Activity5" "Question2" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question2", id "a5q2third", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question2" "Answer3") ] []
            , label [ for "a5q2third" ] [ getAnswerText model "Activity5" "Question2" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question2", id "a5q2fourth", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question2" "Answer4") ] []
            , label [ for "a5q2fourth" ] [ getAnswerText model "Activity5" "Question2" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question2", id "a5q2fifth", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question2" "Answer5") ] []
            , label [ for "a5q2fifth" ] [ getAnswerText model "Activity5" "Question2" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question2", id "a5q2sixth", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question2" "Answer6") ] []
            , label [ for "a5q2sixth" ] [ getAnswerText model "Activity5" "Question2" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity5" "Question2") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text "The correct answer is: официант = waiter; think about someone officiating over the dining room at a restaurant"
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewEighteenthQuestion : Model -> Html Msg
viewEighteenthQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity5" "Question3"

        answerCorrect =
            checkAnswerCorrect model "Activity5" "Question3"

        solutionVisible =
            checkButtonClicked model "Activity5" "Question3"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "A circular series of items (poems, procedures, reactions)" ]
        , Html.form []
            [ input [ type_ "radio", name "activity5_question3", id "a5q3first", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question3" "Answer1") ] []
            , label [ for "a5q3first" ] [ getAnswerText model "Activity5" "Question3" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question3", id "a5q3second", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question3" "Answer2") ] []
            , label [ for "a5q3second" ] [ getAnswerText model "Activity5" "Question3" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question3", id "a5q3third", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question3" "Answer3") ] []
            , label [ for "a5q3third" ] [ getAnswerText model "Activity5" "Question3" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question3", id "a5q3fourth", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question3" "Answer4") ] []
            , label [ for "a5q3fourth" ] [ getAnswerText model "Activity5" "Question3" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question3", id "a5q3fifth", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question3" "Answer5") ] []
            , label [ for "a5q3fifth" ] [ getAnswerText model "Activity5" "Question3" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question3", id "a5q3sixth", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question3" "Answer6") ] []
            , label [ for "a5q3sixth" ] [ getAnswerText model "Activity5" "Question3" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity5" "Question3") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Markdown.toHtml [ attribute "class" "markdown-link" ] """The correct answer is: 1. цикл = cycle, as a word from Greek, the English y is often expressed in Russian with an **и**."""
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewNineteenthQuestion : Model -> Html Msg
viewNineteenthQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity5" "Question4"

        answerCorrect =
            checkAnswerCorrect model "Activity5" "Question4"

        solutionVisible =
            checkButtonClicked model "Activity5" "Question4"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "Instructions received for preparing something; instructions to take a certain medical preparation" ]
        , Html.form []
            [ input [ type_ "radio", name "activity5_question4", id "a5q4first", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question4" "Answer1") ] []
            , label [ for "a5q4first" ] [ getAnswerText model "Activity5" "Question4" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question4", id "a5q4second", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question4" "Answer2") ] []
            , label [ for "a5q4second" ] [ getAnswerText model "Activity5" "Question4" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question4", id "a5q4third", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question4" "Answer3") ] []
            , label [ for "a5q4third" ] [ getAnswerText model "Activity5" "Question4" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question4", id "a5q4fourth", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question4" "Answer4") ] []
            , label [ for "a5q4fourth" ] [ getAnswerText model "Activity5" "Question4" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question4", id "a5q4fifth", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question4" "Answer5") ] []
            , label [ for "a5q4fifth" ] [ getAnswerText model "Activity5" "Question4" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question4", id "a5q4sixth", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question4" "Answer6") ] []
            , label [ for "a5q4sixth" ] [ getAnswerText model "Activity5" "Question4" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity5" "Question4") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Markdown.toHtml [ attribute "class" "markdown-link" ] """
The correct answer is: рецепт = prescription (medical sense of word); recipe (cooking sense of word)

The word **рецепт** is from Latin, and is related to the English word French **received** / **receipt**.
                                """
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewTwentiethQuestion : Model -> Html Msg
viewTwentiethQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity5" "Question5"

        answerCorrect =
            checkAnswerCorrect model "Activity5" "Question5"

        solutionVisible =
            checkButtonClicked model "Activity5" "Question5"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "Ideal or aspirational notion that guide actions" ]
        , Html.form []
            [ input [ type_ "radio", name "activity5_question5", id "a5q5first", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question5" "Answer1") ] []
            , label [ for "a5q5first" ] [ getAnswerText model "Activity5" "Question5" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question5", id "a5q5second", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question5" "Answer2") ] []
            , label [ for "a5q5second" ] [ getAnswerText model "Activity5" "Question5" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question5", id "a5q5third", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question5" "Answer3") ] []
            , label [ for "a5q5third" ] [ getAnswerText model "Activity5" "Question5" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question5", id "a5q5fourth", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question5" "Answer4") ] []
            , label [ for "a5q5fourth" ] [ getAnswerText model "Activity5" "Question5" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question5", id "a5q5fifth", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question5" "Answer5") ] []
            , label [ for "a5q5fifth" ] [ getAnswerText model "Activity5" "Question5" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity5_question5", id "a5q5sixth", class "guide-question-button", onClick (UpdateAnswer "Activity5" "Question5" "Answer6") ] []
            , label [ for "a5q5sixth" ] [ getAnswerText model "Activity5" "Question5" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity5" "Question5") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Markdown.toHtml [ attribute "class" "markdown-link" ] """
The correct answer is: принцип = principle

The Latin word is **principium**, and the grammatical ending -ium is usually not reflected when Russian borrows a Latin word.

The final word in this set **церемония** is equivalent to English **ceremony**. 
                                """
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewSixthSection : Html Msg
viewSixthSection =
    Markdown.toHtml [ attribute "class" "markdown-link" ] """
#### International words with the letter h

Until the mid-twentieth century, when international words that contained an **h** or **h sound** came into Russian, the h was often expressed with the letter г.  For this reason, Shakespeare's famous tragedy Hamlet is known as **Гамлет** in Russian.  The г is pronounced as a normal **г**.

Since the mid-twentieth century, the **h** of English-based international words is usually expressed in Russian with the letter **х**.   For this reason, second-hand stories are known in Russian now as **секонд-хенд**, and the American food item "hot dog" is known in Russian as **хот-дог**.
"""


viewInstructionsSixthActivity : Html Msg
viewInstructionsSixthActivity =
    Markdown.toHtml [ attribute "class" "markdown-link" ] """
#### Activity 6

Recognizing international words featuring the letter h as Russian г.

Instructions. Sound out the six Russian words on the line below. Decide which of them fit the meanings.

героиня гармония гипотеза алкоголь горизонт госпиталь
"""


viewTwentyFirstQuestion : Model -> Html Msg
viewTwentyFirstQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity6" "Question1"

        answerCorrect =
            checkAnswerCorrect model "Activity6" "Question1"

        solutionVisible =
            checkButtonClicked model "Activity6" "Question1"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "Sounds that blend together well" ]
        , Html.form []
            [ input [ type_ "radio", name "activity6_question1", id "a6q1first", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question1" "Answer1") ] []
            , label [ for "a6q1first" ] [ getAnswerText model "Activity6" "Question1" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question1", id "a6q1second", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question1" "Answer2") ] []
            , label [ for "a6q1second" ] [ getAnswerText model "Activity6" "Question1" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question1", id "a6q1third", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question1" "Answer3") ] []
            , label [ for "a6q1third" ] [ getAnswerText model "Activity6" "Question1" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question1", id "a6q1fourth", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question1" "Answer4") ] []
            , label [ for "a6q1fourth" ] [ getAnswerText model "Activity6" "Question1" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question1", id "a6q1fifth", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question1" "Answer5") ] []
            , label [ for "a6q1fifth" ] [ getAnswerText model "Activity6" "Question1" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question1", id "a6q1sixth", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question1" "Answer6") ] []
            , label [ for "a6q1sixth" ] [ getAnswerText model "Activity6" "Question1" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity6" "Question1") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text "The correct answer is: гармония = harmony."
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewTwentySecondQuestion : Model -> Html Msg
viewTwentySecondQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity6" "Question2"

        answerCorrect =
            checkAnswerCorrect model "Activity6" "Question2"

        solutionVisible =
            checkButtonClicked model "Activity6" "Question2"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "Female main character in a book or film" ]
        , Html.form []
            [ input [ type_ "radio", name "activity6_question2", id "a6q2first", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question2" "Answer1") ] []
            , label [ for "a6q2first" ] [ getAnswerText model "Activity6" "Question2" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question2", id "a6q2second", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question2" "Answer2") ] []
            , label [ for "a6q2second" ] [ getAnswerText model "Activity6" "Question2" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question2", id "a6q2third", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question2" "Answer3") ] []
            , label [ for "a6q2third" ] [ getAnswerText model "Activity6" "Question2" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question2", id "a6q2fourth", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question2" "Answer4") ] []
            , label [ for "a6q2fourth" ] [ getAnswerText model "Activity6" "Question2" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question2", id "a6q2fifth", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question2" "Answer5") ] []
            , label [ for "a6q2fifth" ] [ getAnswerText model "Activity6" "Question2" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question2", id "a6q2sixth", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question2" "Answer6") ] []
            , label [ for "a6q2sixth" ] [ getAnswerText model "Activity6" "Question2" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity6" "Question2") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text "The correct answer is: героиня = heroine; the drug heroin will be героин in Russian."
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewTwentyThirdQuestion : Model -> Html Msg
viewTwentyThirdQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity6" "Question3"

        answerCorrect =
            checkAnswerCorrect model "Activity6" "Question3"

        solutionVisible =
            checkButtonClicked model "Activity6" "Question3"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "Place to treat wounded soldiers" ]
        , Html.form []
            [ input [ type_ "radio", name "activity6_question3", id "a6q3first", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question3" "Answer1") ] []
            , label [ for "a6q3first" ] [ getAnswerText model "Activity6" "Question3" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question3", id "a6q3second", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question3" "Answer2") ] []
            , label [ for "a6q3second" ] [ getAnswerText model "Activity6" "Question3" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question3", id "a6q3third", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question3" "Answer3") ] []
            , label [ for "a6q3third" ] [ getAnswerText model "Activity6" "Question3" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question3", id "a6q3fourth", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question3" "Answer4") ] []
            , label [ for "a6q3fourth" ] [ getAnswerText model "Activity6" "Question3" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question3", id "a6q3fifth", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question3" "Answer5") ] []
            , label [ for "a6q3fifth" ] [ getAnswerText model "Activity6" "Question3" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question3", id "a6q3sixth", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question3" "Answer6") ] []
            , label [ for "a6q3sixth" ] [ getAnswerText model "Activity6" "Question3" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity6" "Question3") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Markdown.toHtml [ attribute "class" "markdown-link" ] """
The correct answer is: госпиталь = hospital, but usually used only about military and field hospitals. Civilian hospitals in Russian are called **больница**, a place for the sick ( **больные** ) and people who have pain (**боль**).
                                """
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewTwentyFourthQuestion : Model -> Html Msg
viewTwentyFourthQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity6" "Question4"

        answerCorrect =
            checkAnswerCorrect model "Activity6" "Question4"

        solutionVisible =
            checkButtonClicked model "Activity6" "Question4"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "What a scientist tests in an experiment" ]
        , Html.form []
            [ input [ type_ "radio", name "activity6_question4", id "a6q4first", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question4" "Answer1") ] []
            , label [ for "a6q4first" ] [ getAnswerText model "Activity6" "Question4" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question4", id "a6q4second", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question4" "Answer2") ] []
            , label [ for "a6q4second" ] [ getAnswerText model "Activity6" "Question4" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question4", id "a6q4third", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question4" "Answer3") ] []
            , label [ for "a6q4third" ] [ getAnswerText model "Activity6" "Question4" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question4", id "a6q4fourth", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question4" "Answer4") ] []
            , label [ for "a6q4fourth" ] [ getAnswerText model "Activity6" "Question4" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question4", id "a6q4fifth", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question4" "Answer5") ] []
            , label [ for "a6q4fifth" ] [ getAnswerText model "Activity6" "Question4" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question4", id "a6q4sixth", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question4" "Answer6") ] []
            , label [ for "a6q4sixth" ] [ getAnswerText model "Activity6" "Question4" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity6" "Question4") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Markdown.toHtml [ attribute "class" "markdown-link" ] """
The correct answer is: гипотеза = hypothesis

You have to make multiple substitutions to see the connection here: Russian **и** often takes the place of the Latin letter **y**; Russian **т** often takes the place of **th**, and finally the grammatical ending **-is** is truncated in Russian and replaced by **-а**.
                                """
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewTwentyFifthQuestion : Model -> Html Msg
viewTwentyFifthQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity6" "Question5"

        answerCorrect =
            checkAnswerCorrect model "Activity6" "Question5"

        solutionVisible =
            checkButtonClicked model "Activity6" "Question5"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "The imaginary line where the land meets the sky" ]
        , Html.form []
            [ input [ type_ "radio", name "activity6_question5", id "a6q5first", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question5" "Answer1") ] []
            , label [ for "a6q5first" ] [ getAnswerText model "Activity6" "Question5" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question5", id "a6q5second", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question5" "Answer2") ] []
            , label [ for "a6q5second" ] [ getAnswerText model "Activity6" "Question5" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question5", id "a6q5third", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question5" "Answer3") ] []
            , label [ for "a6q5third" ] [ getAnswerText model "Activity6" "Question5" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question5", id "a6q5fourth", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question5" "Answer4") ] []
            , label [ for "a6q5fourth" ] [ getAnswerText model "Activity6" "Question5" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question5", id "a6q5fifth", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question5" "Answer5") ] []
            , label [ for "a6q5fifth" ] [ getAnswerText model "Activity6" "Question5" "Answer5" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity6_question5", id "a6q5sixth", class "guide-question-button", onClick (UpdateAnswer "Activity6" "Question5" "Answer6") ] []
            , label [ for "a6q5sixth" ] [ getAnswerText model "Activity6" "Question5" "Answer6" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity6" "Question5") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Markdown.toHtml [ attribute "class" "markdown-link" ] 
                                """
The correct answer is: горизонт = horizon

Like English, the Russian word can be used in metaphorical senses as well as geographic and geometric meanings.

The final word in this set **алкоголь** = English **alchohol** borrowed from the Arabic **alkohl**. 
                                """
                                ]
                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewSeventhSection : Html Msg
viewSeventhSection =
    Markdown.toHtml [ attribute "class" "markdown-link" ] """
#### International words: Proceed with caution

When you encounter a word in Russian and you sound it out in trying to recognize it, it is good to remember that, while there are many international 
words in Russian, Russian also has its own core vocabulary. Once you've sounded out the Russian word, be sure to consider whether it could be from 
Russian's core vocabulary or an international word adopted from another language. Most words that Russian has borrowed will be for concepts or innovations 
that started elsewhere and came to Russian.  Context should also help you decide if the word is an international word or not. 
"""


viewEigthSection : Html Msg
viewEigthSection =
    div []
        [ table [] <|
            [ caption [] [ text "International and non-international words" ]
            , tr []
                [ th [] [ text "Russian word" ]
                , th [] [ text "Sounds like:" ]
                , th [] [ text "Context" ]
                , th [] [ text "Comments" ]
                ]
            , tr []
                [ td [] [ text "стол" ]
                , td [] [ Markdown.toHtml [ attribute "class" "markdown-link" ] 
                    """
"stole" 

Could it be related to "stealing"? 
                    """ 
                    ]
                , td [] [ Markdown.toHtml [ attribute "class" "markdown-link" ] 
                    """
Вот ваш стол. Тут можете работать.

Here's your ___. You can work here. 
                    """ 
                    ]
                , td [] [ Markdown.toHtml [ attribute "class" "markdown-link" ] 
                    """
Although **стол** sounds like **stole**, the Russian word is a noun meaning "table," and that makes it unlikely to be related to an English verb. 
Furthermore, **steal** is one of those core concepts in a culture, and it is unlikely that Russian needed to borrow a word for that notion.
                    """ 
                    ]
                ]
            , tr []
                [ td [] [ text "магазин" ]
                , td [] [ Markdown.toHtml [ attribute "class" "markdown-link" ] 
                    """
"magazin"

Could it mean "magazine"?
                    """ 
                    ]
                , td [] [ Markdown.toHtml [ attribute "class" "markdown-link" ] 
                    """
В 1995 году в Internet появился первый книжный магазин ― знаменитый Amazon.com.

In 1995 the famous Amazon.com was the first internet book ___ to appear on the internet. 
                    """ 
                    ]
                , td [] [ Markdown.toHtml [ attribute "class" "markdown-link" ] 
                    """
**Магазин** is indeed an international word, borrowed into Russian. However, it was borrowed from French, where **magazin** is a **store**, not a periodical to read. Words like this are often called "false friends" because, although they look the same across languages, they have completely different meanings.
                    """ 
                    ]
                ]
            , tr []
                [ td [] [ text "смелый" ]
                , td [] [ Markdown.toHtml [ attribute "class" "markdown-link" ] 
                    """
"smely"

Could it be related to "smelly"?
                    """ 
                    ]
                , td [] [ Markdown.toHtml [ attribute "class" "markdown-link" ] 
                    """
Костя в жизни был не очень смелый, и он боялся лезть в драку.

Kostya in life wasn't very ___ and he was afraid of getting into a fight.
                    """ 
                    ]
                , td [] [ Markdown.toHtml [ attribute "class" "markdown-link" ] 
                    """
Although **смелый** sounds like **smelly**, they are not at all related. The Russian word **смелый** means **bold**, **daring** and is related to the verb **сметь**, which means "to dare." This is one of those core concepts in a culture, and it is unlikely that Russian needed to borrow a word for that notion.
                    """ 
                    ]
                ]
            , tr []
                [ td [] [ text "пластинка" ]
                , td [] [ Markdown.toHtml [ attribute "class" "markdown-link" ] 
                    """
"plastinka"

Could it be related to plastic?
                    """ 
                    ]
                , td [] [ Markdown.toHtml [ attribute "class" "markdown-link" ] 
                    """
В 70-ые года в детстве Маша любила "Битлз" и все время слушала пластинки этой группы.

In the 1970s, in her childhood Masha loved the Beatles and listened to that group's ___ all the time.
                    """ 
                    ]
                , td [] [ Markdown.toHtml [ attribute "class" "markdown-link" ] 
                    """
Although **ластинка** sounds almost like **plastic**, the words are not at all related. The Russian word **пластинка** means **record (vinyl disk with recorded audio)** and is related to the adjective **плоский**, which means "flat."
                    """ 
                    ]
                ]
            , tr []
                [ td [] [ text "ремонт" ]
                , td [] [ Markdown.toHtml [ attribute "class" "markdown-link" ] 
                    """
"remont"

Could it be related to "remounting"?
                    """ 
                    ]
                , td [] [ Markdown.toHtml [ attribute "class" "markdown-link" ] 
                    """
К концу января ремонт был закончен. Кухня была вся новая.

By the end of January the ___ was finished. The kitchen was completely new.
                    """ 
                    ]
                , td [] [ Markdown.toHtml [ attribute "class" "markdown-link" ] 
                    """
**Ремонт** is indeed an international word, borrowed into Russian. However, it was borrowed from French, where **remonte** means **remodeling** and **renovation**.
                    """ 
                    ]
                ]
            ]
        ]




-- VIEW UTILITY


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