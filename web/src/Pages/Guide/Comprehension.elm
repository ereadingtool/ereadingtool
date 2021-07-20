module Pages.Guide.Comprehension exposing (..)

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
                                [ ( "Answer1", Answer "1" False False )
                                , ( "Answer2", Answer "2" True False )
                                , ( "Answer3", Answer "3" False False )
                                , ( "Answer4", Answer "Can't tell." False False )
                                ]
                            )
                            { showButton = False, showSolution = False }
                      )
                    , ( "Question2"
                      , Question
                            (Dict.fromList
                                [ ( "Answer1", Answer "Yes" False False )
                                , ( "Answer2", Answer "No" True False )
                                , ( "Answer3", Answer "Can't tell." False False )
                                ]
                            )
                            { showButton = False, showSolution = False }
                      )
                    , ( "Question3"
                      , Question
                            (Dict.fromList
                                [ ( "Answer1", Answer "Small" True False )
                                , ( "Answer2", Answer "Large" False False )
                                , ( "Answer3", Answer "Plain" True False )
                                , ( "Answer4", Answer "Well-equipped" False False )
                                , ( "Answer5", Answer "Comfortable" False False )
                                , ( "Answer6", Answer "has sails" False False )
                                , ( "Answer7", Answer "has oars" True False )
                                ]
                            )
                            { showButton = False, showSolution = False }
                      )
                    , ( "Question4"
                      , Question
                            (Dict.fromList
                                [ ( "Answer1", Answer "They're taking a pleasure trip." False False )
                                , ( "Answer2", Answer "They are fishing." False False )
                                , ( "Answer3", Answer "They are hauling things across the river." False False )
                                , ( "Answer4", Answer "They are trying to rescue someone who's drowning." False False )
                                , ( "Answer5", Answer "Can't tell." True False )
                                ]
                            )
                            { showButton = False, showSolution = False }
                      )
                    , ( "Question5"
                      , Question
                            (Dict.fromList
                                [ ( "Answer1", Answer "Cheerful" False False )
                                , ( "Answer2", Answer "Anxious" True False )
                                , ( "Answer3", Answer "Bored" False False )
                                , ( "Answer4", Answer "Can't tell." True False )
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
    { title = "Guide | Comprehension"
    , body =
        [ div [ id "body" ]
            [ div [ id "about" ]
                [ div [ id "about-box" ]
                    [ div [ id "title" ] [ text "Comprehension" ]
                    , viewTabs
                    , viewFirstSection
                    , viewSecondSection
                    , viewThirdSection
                    , viewFirstQuestion model
                    , viewSecondQuestion model
                    , viewThirdQuestion model
                    , viewFourthQuestion model
                    , viewFifthQuestion model
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
            , class "selected-guide-tab"
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
        ]


viewFirstSection : Html Msg
viewFirstSection =
    Markdown.toHtml [ attribute "class" "markdown-link" ] """
### Focus on Comprehension: Reading through unknown words

Even in your first language there will be texts that you can read and comprehend where you do not know every word in the text. Sometimes, 
you can figure out the meaning of the unfamiliar word from context; other times, you can look up the unfamiliar word if it seems important; 
most times, the unfamiliar word may not keep you from understanding the basic meaning of the passage.

Try these reading strategies for yourself on the text below where 30% of the words have been replaced with non-sense words.

#### Pre-reading Work:
The paragraph below starts a chapter of an English novel published in the 1860s. The title of the chapter is: A Boat on the River 

**Activity 1**. Before reading, stop and brainstorming about what might be in such a chapter. Make hypotheses. Try to visualize the possible 
scene. What does a 19th century boat on a river look like? How might people be dressed? What might be visible on the banks of the river?

**Activity 2**. After you've completed your brainstorming, go on to read the text below. You won’t know every word, but keep on reading to 
the end, and make as much sense out of the passage as you can.
"""


viewSecondSection : Html Msg
viewSecondSection =
    div [ class "sample-passage" ]
        [ Html.em [] [ Html.text "A Boat on the River" ]
        , Html.br [] []
        , Html.br [] []
        , Html.text """
        The gapels in this boat were those of a foslaint man with nabelked amboned hair and a trathmollated face, and a finlact girl of nineteen or twenty, 
        nabbastly like him to be sorbicable as his fornoy. The girl zarred, pulling a pair of sculls very easily; the man, with the rudder-lines slack in 
        his dispers, and his dispers loose in his waistband, kept an eager look out. He had no net, galeaft, or line, and he could not be a paplil; his boat 
        had no exbain for a sitter, no paint, no debilk, no bepult beyond a rusty calben and a lanop of rope, and he could not be a waterman; his boat was too 
        anem and too divey to take in besder for delivery, and he could not be a river-carrier; there was no paff to what he looked for, sar he looked for 
        something, with a most nagril and searching profar. The befin, which had turned an hour before, was melucting zopt, and his eyes hasteled every little 
        furan and gaist in its broad sweep, as the boat made bilp ducasp against it, or drove stern foremost before it, according as he calbained his fornoy by 
        a calput of his head. She hasteled his face as parnly as he hasteled the river. But, in the astortant of her look there was a touch of bazad or fisd.
        """
        ]


viewThirdSection : Html Msg
viewThirdSection =
    Markdown.toHtml [] """
### Learning to read through unfamiliar words

How many of the comprehension questions were you able to answer correctly? Did the presence of so many unfamiliar words keep you from forming a general impression of what is going on in this passage? 

Which ones of your hypotheses about the text were accurate? Which ones did you need to abandon? Did trying to visualize what the scene might look like help you in reading the text?

How can you apply this strategy when you are reading a text in Russian?

In the next section of this strategy instruction, you will work on using context to guess the meaning of unfamiliar words.


## Comprehension Questions

After reading the passage above, complete these comprehension questions. After making your choice, click the “check answer” tab to see the correct answer and the reasoning behind it.
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
        [ Html.div [] [ text "How many people are there in the boat?" ]
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
                                [ Html.text "The correct answer is: 2"
                                , Html.br [] []
                                , Html.text """There are two people in the boat, a man and a girl. They are mentioned in the first sentence, and then they are referred to only as "he" and "she." """
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
        [ Html.div [] [ text "Are the people in the boat strangers to each other?" ]
        , Html.form []
            [ input [ type_ "radio", name "activity1_question2", id "a1q2first", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question2" "Answer1") ] []
            , label [ for "a1q2first" ] [ getAnswerText model "Activity1" "Question2" "Answer1" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question2", id "a1q2second", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question2" "Answer2") ] []
            , label [ for "a1q2second" ] [ getAnswerText model "Activity1" "Question2" "Answer2" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question2", id "a1q2third", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question2" "Answer3") ] []
            , label [ for "a1q2third" ] [ getAnswerText model "Activity1" "Question2" "Answer3" ]
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
                                [ Html.text "The most likely answer is: No"
                                , Html.br [] []
                                , Html.text """Although it's not directly stated that they know each other, we can infer that since the man is able to communicate to the girl 
                                using his head ("according as he calbained his fornoy by a calput of his head"), and the phrase ("nabbastly like him to be sorbicable as his fornoy") 
                                probably explains the relationship between them. """
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
        [ Html.div [] [ text "What kind of boat is it?" ]
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
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question3", id "a1q3sixth", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question3" "Answer6") ] []
            , label [ for "a1q3sixth" ] [ getAnswerText model "Activity1" "Question3" "Answer6" ]
            , Html.br [] []
            , input [ type_ "radio", name "activity1_question3", id "a1q3seventh", class "guide-question-button", onClick (UpdateAnswer "Activity1" "Question3" "Answer7") ] []
            , label [ for "a1q3seventh" ] [ getAnswerText model "Activity1" "Question3" "Answer7" ]
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
                                [ Html.text """The most likely answers are: "Small", "Plain", and "has oars". """
                                , Html.br [] []
                                , Html.text """That the boat is unfit for commercial purposes "he could not be a waterman...and he could not be a river-carrier" suggests its 
                                small size; the list of things that it is missing ("no exbain for a sitter, no paint, no debilk, no bepult beyond a rusty calben and a lanop of rope") 
                                suggests that it is poor and plain; and that it's a row boat is suggested in the phrase ("The girl zarred, pulling a pair of sculls very easily"). """
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
        [ Html.div [] [ text "Why are the people out on the river?" ]
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
                                [ Html.text """The best answer here is: Can't tell. """
                                , Html.br [] []
                                , Html.text """We can rule out choices involving fishing or hauling items since the text tells us that the man doesn't have a net or a line that he'd need for fishing, and 
                                the boat is unfit for the commercial purposes of river transport. A pleasure trip seems unlikely since the boat isn't particularly comfortable or well-appointed. 
                                A rescue mission also is unlikely since there's no reference to urgency or someone in the water. """
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
        [ Html.div [] [ text "What is the mood of the people in the boat?" ]
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
                                [ Html.text """The best answers here are: Anxious or Can't tell. """
                                , Html.br [] []
                                , Html.text """While the plainness of the boat and the absence of so many basics suggests that the people in the boat are very poor and that the 
                                trip isn't to bring them pleasure, so "Cheerful" seems unlikely. "Bored" also seems unlikely since the man is described as looking for something 
                                ("eager look out" and "what he looked for" and "searching."). The man's mood doesn't seem to be shared by the girl, and so that suggests some conflict 
                                between the two, and so the mood might be tense or anxious. """
                                ]

                          else
                            div [] []
                        ]
                    ]

              else
                div [] []
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
