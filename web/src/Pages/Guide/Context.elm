module Pages.Guide.Context exposing (..)

import Dict exposing (Dict)
import Help.Activities exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Markdown
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)


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
                                [ ( "Answer1", Answer "boxes" False False )
                                , ( "Answer2", Answer "animals" False False )
                                , ( "Answer3", Answer "figures" True False )
                                , ( "Answer4", Answer "fish" False False )
                                , ( "Answer5", Answer "uniforms" False False )
                                ]
                            )
                            { showButton = False, showSolution = False }
                      )
                    , ( "Question2"
                      , Question
                            (Dict.fromList
                                [ ( "Answer1", Answer "loops" False False )
                                , ( "Answer2", Answer "hands" True False )
                                , ( "Answer3", Answer "belts" False False )
                                , ( "Answer4", Answer "sleeves" False False )
                                , ( "Answer5", Answer "knees" False False )
                                ]
                            )
                            { showButton = False, showSolution = False }
                      )
                    , ( "Question3"
                      , Question
                            (Dict.fromList
                                [ ( "Answer1", Answer "large" False False )
                                , ( "Answer2", Answer "grand" False False )
                                , ( "Answer3", Answer "new" False False )
                                , ( "Answer4", Answer "small" True False )
                                , ( "Answer5", Answer "ancient" False False )
                                ]
                            )
                            { showButton = False, showSolution = False }
                      )
                    , ( "Question4"
                      , Question
                            (Dict.fromList
                                [ ( "Answer1", Answer "interest" False False )
                                , ( "Answer2", Answer "gaze" True False )
                                , ( "Answer3", Answer "thirst" False False )
                                , ( "Answer4", Answer "need" False False )
                                , ( "Answer5", Answer "binoculars" False False )
                                ]
                            )
                            { showButton = False, showSolution = False }
                      )
                    , ( "Question5"
                      , Question
                            (Dict.fromList
                                [ ( "Answer1", Answer "hated" False False )
                                , ( "Answer2", Answer "loved" False False )
                                , ( "Answer3", Answer "watched" True False )
                                , ( "Answer4", Answer "avoided" False False )
                                , ( "Answer5", Answer "stunned" False False )
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
                                [ ( "Answer1", Answer "galeaft" False False )
                                , ( "Answer2", Answer "exbain" False False )
                                , ( "Answer3", Answer "debilk" False False )
                                , ( "Answer4", Answer "bepult" False False )
                                , ( "Answer5", Answer "paplil" True False )
                                ]
                            )
                            { showButton = False, showSolution = False }
                      )
                    , ( "Question2"
                      , Question
                            (Dict.fromList
                                [ ( "Answer1", Answer "zopt" False False )
                                , ( "Answer2", Answer "befin" True False )
                                , ( "Answer3", Answer "furan" False False )
                                , ( "Answer4", Answer "ducasp" False False )
                                , ( "Answer5", Answer "paff" False False )
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
                updatedActivities =
                    accessActivity model activity
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
                updatedActivities =
                    accessActivity model activity
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
            Question (Dict.map (\_ an -> { an | selected = False }) (answers q)) { showButton = True, showSolution = False }

        Nothing ->
            Question (Dict.fromList []) { showButton = False, showSolution = False }


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
        clearedQuestion =
            accessActivity model activityKey
                |> accessQuestion questionKey
                |> clearQuestion
    in
    Question (Dict.update answerKey (\_ -> updatedAnswer) (answers clearedQuestion)) { showButton = True, showSolution = False }


updateQuestionShowsSolution : Maybe Question -> Question
updateQuestionShowsSolution maybeQuestion =
    case maybeQuestion of
        Just q ->
            Question (answers q) { showButton = True, showSolution = True }

        Nothing ->
            Question (Dict.fromList []) { showButton = False, showSolution = False }


updateActivity : Model -> String -> String -> Question -> Activity
updateActivity model activityKey questionKey updatedQuestion =
    let
        maybeActivity =
            accessActivity model activityKey
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
    { title = "Guide | Context"
    , body =
        [ div [ id "body" ]
            [ div [ id "about" ]
                [ div [ id "about-box" ]
                    [ div [ id "title" ] [ text "Context" ]
                    , viewTabs
                    , viewFirstSection
                    , viewSecondSection
                    , viewInstructionsFirstActivity
                    , viewFirstQuestion model
                    , viewSecondQuestion model
                    , viewThirdQuestion model
                    , viewFourthQuestion model
                    , viewFifthQuestion model
                    , viewThirdSection
                    , viewFourthSection
                    , viewInstructionsSecondActivity
                    , viewSixthQuestion model
                    , viewSeventhQuestion model
                    , viewFifthSection
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
            , class "selected-guide-tab"
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
        ]


viewFirstSection : Html Msg
viewFirstSection =
    Markdown.toHtml [ attribute "class" "markdown-link" ] """
### Using context to guess unknown words

While you may not be able to guess the meaning of every unfamiliar word from context, you should be able to narrow the possible range of meanings of specific words.  
Use context and these questions to help you narrow down the possible meaning of key words. 
1. If the unknown word seems to be a noun, does it refer to a person? To a place? To a thing? To a concept? Does it seem to be a synonym for something already mentioned in the text?
2. If it’s an adjective, what word does it modify? Does it seem to suggest a positive or a negative quality? Does it refer to time? Or place? 
3. If it’s a verb, who seems to be the doer of the action? Is there a direct object of the action? Does it suggest motion (into/to/towards) a person or place? Does it suggest 
communication (to someone or with someone)? Is it present/future tense? Or past?
"""


viewSecondSection : Html Msg
viewSecondSection =
    div [ class "sample-passage" ]
        [ Html.em [] [ Html.text "A Boat on the River" ]
        , Html.br [] []
        , Html.br [] []
        , Html.text "The "
        , Html.strong [] [ Html.text "gapels" ]
        , Html.text """ in this boat were those of a foslaint man with nabelked amboned hair and a trathmollated face, and a finlact girl of nineteen or twenty, 
        nabbastly like him to be sorbicable as his fornoy. The girl zarred, pulling a pair of sculls very easily; the man, with the rudder-lines slack in 
        his """
        , Html.strong [] [ Html.text "dispers" ]
        , Html.text " and his "
        , Html.strong [] [ Html.text "dispers" ]
        , Html.text """ loose in his waistband, kept an eager look out. He had no net, galeaft, or line, and he could not be a paplil; his boat 
        had no exbain for a sitter, no paint, no debilk, no bepult beyond a rusty calben and a lanop of rope, and he could not be a waterman; his boat was too """
        , Html.strong [] [ Html.text "anem" ]
        , Html.text " and too "
        , Html.strong [] [ Html.text "divey" ]
        , Html.text """ to take in besder for delivery, and he could not be a river-carrier; there was no paff to what he looked for, sar he looked for 
        something, with a most nagril and searching """
        , Html.strong [] [ Html.text "profar" ]
        , Html.text ". The befin, which had turned an hour before, was melucting zopt, and his eyes "
        , Html.strong [] [ Html.text "hasteled" ]
        , Html.text """ every little furan and gaist in its broad sweep, as the boat made bilp ducasp against it, or drove stern foremost before it, according as he calbained his fornoy by 
        a calput of his head. She """
        , Html.strong [] [ Html.text "hasteled" ]
        , Html.text " his face as parnly as he "
        , Html.strong [] [ Html.text "hasteled" ]
        , Html.text " the river. But, in the astortant of her look there was a touch of bazad or fisd."
        ]


viewInstructionsFirstActivity : Html Msg
viewInstructionsFirstActivity =
    div []
        [ Html.br [] []
        , Html.strong [] [ Html.text "Instructions" ]
        , Html.br [] []
        , Html.br [] []
        , Html.text """Using context clues from the text above, try to guess the meaning of these nonsense words from the set of words provided. 
                                To help you find the words in the text, they have been put in bold-face. Be sure to re-read the sentence or section of the text before making your guess."""
        ]


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
        [ Html.div [] [ text "Gapels" ]
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
                                [ Html.text """The correct answer is "figures" """
                                , Html.br [] []
                                , Html.text """Gapels has to be some kind of collective term for the man and the girl in the boat. Now re-read that sentence again and see if 
                                you can guess any other words that are in the immediate context."""
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
        [ Html.div [] [ text "Dispers" ]
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
                                [ Html.text """The correct answer is "hands" """
                                , Html.br [] []
                                , Html.text """Dispers have to be some part of the man (e.g., hands, fingers, fists) that can both hold a slack line, and also fit in his waistband."""
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
            checkAnswerSelected model "Activity1" "Question3"

        answerCorrect =
            checkAnswerCorrect model "Activity1" "Question3"

        solutionVisible =
            checkButtonClicked model "Activity1" "Question3"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "Anem/divey" ]
        , Html.form []
            [ input [ type_ "radio", name "activity1_question3", id "a1q3first", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question3" "Answer1") ] []
            , label [ for "a1q3first" ] [ getAnswerText model "Activity1" "Question3" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question3", id "a1q3second", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question3" "Answer2") ] []
            , label [ for "a1q3second" ] [ getAnswerText model "Activity1" "Question3" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question3", id "a1q3third", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question3" "Answer3") ] []
            , label [ for "a1q3third" ] [ getAnswerText model "Activity1" "Question3" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question3", id "a1q3fourth", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question3" "Answer4") ] []
            , label [ for "a1q3fourth" ] [ getAnswerText model "Activity1" "Question3" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question3", id "a1q3fifth", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question3" "Answer5") ] []
            , label [ for "a1q3fifth" ] [ getAnswerText model "Activity1" "Question3" "Answer5" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity1" "Question3") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text """The correct answer is: "small" """
                                , Html.br [] []
                                , Html.text """The boat here is defined by what it can't do, and so anem/divey must be synonyms for an undesirable characteristic. "Ancient" 
                                might be possible, although there's nothing that would keep an old boat from being well equipped."""
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
            checkAnswerSelected model "Activity1" "Question4"

        answerCorrect =
            checkAnswerCorrect model "Activity1" "Question4"

        solutionVisible =
            checkButtonClicked model "Activity1" "Question4"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "profar" ]
        , Html.form []
            [ input [ type_ "radio", name "activity1_question4", id "a1q4first", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question4" "Answer1") ] []
            , label [ for "a1q4first" ] [ getAnswerText model "Activity1" "Question4" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question4", id "a1q4second", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question4" "Answer2") ] []
            , label [ for "a1q4second" ] [ getAnswerText model "Activity1" "Question4" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question4", id "a1q4third", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question4" "Answer3") ] []
            , label [ for "a1q4third" ] [ getAnswerText model "Activity1" "Question4" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question4", id "a1q4fourth", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question4" "Answer4") ] []
            , label [ for "a1q4fourth" ] [ getAnswerText model "Activity1" "Question4" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question4", id "a1q4fifth", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question4" "Answer5") ] []
            , label [ for "a1q4fifth" ] [ getAnswerText model "Activity1" "Question4" "Answer5" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity1" "Question4") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text """The best answer here is: "gaze" """
                                , Html.br [] []
                                , Html.text """""binoculars" can't work because the article "a" ("he looked...with a most... profar") rules out the plural binoculars. "thirst" 
                                would mix senses (looking with drinking), and so that seems awkward. "interest", "gaze", and "need" are all possible, but "gaze" best fits with the verb "looked." """
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
            checkAnswerSelected model "Activity1" "Question5"

        answerCorrect =
            checkAnswerCorrect model "Activity1" "Question5"

        solutionVisible =
            checkButtonClicked model "Activity1" "Question5"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "profar" ]
        , Html.form []
            [ input [ type_ "radio", name "activity1_question5", id "a1q5first", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question5" "Answer1") ] []
            , label [ for "a1q5first" ] [ getAnswerText model "Activity1" "Question5" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question5", id "a1q5second", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question5" "Answer2") ] []
            , label [ for "a1q5second" ] [ getAnswerText model "Activity1" "Question5" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question5", id "a1q5third", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question5" "Answer3") ] []
            , label [ for "a1q5third" ] [ getAnswerText model "Activity1" "Question5" "Answer3" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question5", id "a1q5fourth", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question5" "Answer4") ] []
            , label [ for "a1q5fourth" ] [ getAnswerText model "Activity1" "Question5" "Answer4" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question5", id "a1q5fifth", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question5" "Answer5") ] []
            , label [ for "a1q5fifth" ] [ getAnswerText model "Activity1" "Question5" "Answer5" ]
            ]
        , div []
            [ if answerButtonVisible then
                div [ class "guide-button" ]
                    [ button [ onClick (RevealSolution "Activity1" "Question5") ] [ Html.text "Check answer" ]
                    , div []
                        [ if solutionVisible then
                            (if answerCorrect then
                                div [ class "correct-answer-guide" ]

                             else
                                div [ class "incorrect-answer-guide" ]
                            )
                                [ Html.text """The best answer here is: "watched" """
                                , Html.br [] []
                                , Html.text """It can't be "hated" or "avoided" since the man is so eager to look at the river. It could possibly be "loved", but "watched" would fit better with the subject "his eyes." """
                                ]

                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
            ]
        ]


viewThirdSection : Html Msg
viewThirdSection =
    Markdown.toHtml [] """
#### Learning to read through unfamiliar words

How many of the non-sense words were you able to guess correctly? What contextual clues helped you the most?  How might you apply some of those same contextual clues when you try to read in Russian?


### Other Guessing Strategies
Another way to approach guessing the meaning of unfamiliar words in a text is to think about what words are likely to appear in the text. Knowing the title "A boat on the river" of this text, 
you could imagine that the text might contain the words "fisherman" and "tide," and indeed those words are in the original text.  Can you figure out which non-sense words are standing in for them? 
"""


viewFourthSection : Html Msg
viewFourthSection =
    div [ class "sample-passage" ]
        [ Html.em [] [ Html.text "A Boat on the River" ]
        , Html.br [] []
        , Html.br [] []
        , Html.text """
        The gapels in this boat were those of a foslaint man with nabelked amboned hair and a trathmollated face, and a finlact girl of nineteen or twenty, 
        nabbastly like him to be sorbicable as his fornoy. The girl zarred, pulling a pair of sculls very easily; the man, with the rudder-lines slack in 
        his dispers, and his dispers loose in his waistband, kept an eager look out. He had no net, """
        , Html.strong [] [ Html.text "galeaft" ]
        , Html.text ", or line, and he could not be a "
        , Html.strong [] [ Html.text "paplil" ]
        , Html.text "; his boat had no "
        , Html.strong [] [ Html.text "exbain" ]
        , Html.text " for a sitter, no paint, no "
        , Html.strong [] [ Html.text "debilk" ]
        , Html.text ", no "
        , Html.strong [] [ Html.text "bepult" ]
        , Html.text """ beyond a rusty calben and a lanop of rope, and he could not be a waterman; his boat was too 
        anem and too divey to take in besder for delivery, and he could not be a river-carrier; there was no """
        , Html.strong [] [ Html.text "paff" ]
        , Html.text " to what he looked for, sar he looked for something, with a most nagril and searching profar. The "
        , Html.strong [] [ Html.text "befin" ]
        , Html.text ", which had turned an hour before, was melucting "
        , Html.strong [] [ Html.text "zopt" ]
        , Html.text ", and his eyes hasteled every little "
        , Html.strong [] [ Html.text "furan" ]
        , Html.text " and gaist in its broad sweep, as the boat made bilp "
        , Html.strong [] [ Html.text "ducasp" ]
        , Html.text """ against it, or drove stern foremost before it, according as he calbained his fornoy by 
        a calput of his head. She hasteled his face as parnly as he hasteled the river. But, in the astortant of her look there was a touch of bazad or fisd."""
        ]


viewInstructionsSecondActivity : Html Msg
viewInstructionsSecondActivity =
    div []
        [ Html.br [] []
        , Html.strong [] [ Html.text "Instructions" ]
        , Html.br [] []
        , Html.br [] []
        , Html.text """Since this paragraph deals with a boat on a river, it should be no surprise that it contains the words fisherman and tide. Go back and re-read the text. Which non-sense words are standing in for them?"""
        ]


viewSixthQuestion : Model -> Html Msg
viewSixthQuestion model =
    let
        answerButtonVisible =
            checkAnswerSelected model "Activity2" "Question1"

        answerCorrect =
            checkAnswerCorrect model "Activity2" "Question1"

        solutionVisible =
            checkButtonClicked model "Activity2" "Question1"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "fisherman" ]
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
                                [ Html.text """The correct answer is: "paplil" """
                                , Html.br [] []
                                , Html.text """Since the man in the boat is lacking the some of the tools ("He had no net, galeaft, or line") for fishing, we can imagine that "he could not be a paplil / fisherman." """
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
            checkAnswerSelected model "Activity2" "Question2"

        answerCorrect =
            checkAnswerCorrect model "Activity2" "Question2"

        solutionVisible =
            checkButtonClicked model "Activity2" "Question2"
    in
    div [ class "guide-question" ]
        [ Html.div [] [ text "Tide" ]
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
                                [ Html.text """The correct answer is: "befin" """
                                , Html.br [] []
                                , Html.text """Befin is standing in for the noun "tide." We can guess this since the relative clause "which had turned an hour before" could well 
                                describe the tide. "furan" is unlikely since "little" usually doesn't describe tides in English; similarly "ducasp" doesn't fit since a boat can't 
                                make a tide. Similarly, "paff" seems unlikely, since the construction would suggest a word like "hint," or "reason." """
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
    Markdown.toHtml [] """
### Continuing from a guess

Guessing from background knowledge is a risky strategy, especially if you don't know a large number of words in the text.   Be sure to look up the word after guessing to confirm your hypothesis.

You may be able to enhance your ability to guess from background knowledge if you can combine that strategy with some word recognition strategies. For example, in this text, if you knew that **pap** 
meant "**fish**," and the suffix lin often signified the doer of an action, then you'd have stronger justification to guess that **paplin** means "fisherman." Such word formation clues can be powerful 
tools in guessing the meaning of unknown words.

In the next section of this strategy instruction, you will work on deciding how to prioritize which unfamiliar words you would look up in a dictionary.
"""



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

        maybeQuestion =
            case maybeActivities of
                Just activities ->
                    Dict.get questionLabel (questions activities)

                Nothing ->
                    Maybe.map identity Nothing
    in
    case maybeQuestion of
        Just question ->
            showSolution question

        Nothing ->
            False



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
