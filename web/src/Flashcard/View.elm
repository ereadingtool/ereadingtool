module Flashcard.View exposing (..)

import Flashcard.Mode
import Flashcard.Model exposing (..)
import Flashcard.Msg exposing (Msg(..))
import Html exposing (Html, div, span)
import Html.Attributes exposing (attribute, class, classList, id)
import Html.Events exposing (onClick, onDoubleClick, onInput)
import Util


view_mode_choice : Model -> Flashcard.Mode.ModeChoiceDesc -> Html Msg
view_mode_choice _ choice =
    div
        [ classList [ ( "mode-choice", True ), ( "cursor", True ), ( "selected", choice.selected ) ]
        , onClick (SelectMode choice.mode)
        ]
        [ div [ class "name" ] [ Html.text (Flashcard.Mode.modeName choice.mode) ]
        , div [ class "desc" ] [ Html.text choice.desc ]
        , div [ class "select" ]
            [ Html.img
                [ attribute "src" "/static/img/circle_check.svg"
                , attribute "height" "40px"
                , attribute "width" "50px"
                ]
                []
            ]
        ]


view_mode_choices : Model -> List Flashcard.Mode.ModeChoiceDesc -> Html Msg
view_mode_choices model mode_choices =
    div [ id "mode-choices" ] (List.map (view_mode_choice model) mode_choices)


view_additional_notes : Model -> Html Msg
view_additional_notes _ =
    div [ id "notes" ]
        [ Html.text "Note: In review mode double-click a flashcard in order to reveal the answer."
        ]


view_start_nav : Model -> Html Msg
view_start_nav _ =
    div [ id "start", class "cursor", onClick Start ]
        [ Html.text "Start"
        ]


view_prev_nav : Model -> Html Msg
view_prev_nav _ =
    div [ id "prev", class "cursor", onClick Prev ]
        [ Html.img [ attribute "src" "/static/img/angle-left.svg" ] []
        ]


view_next_nav : Model -> Html Msg
view_next_nav _ =
    div [ id "next", class "cursor", onClick Next ]
        [ Html.img [ attribute "src" "/static/img/angle-right.svg" ] []
        ]


view_exception : Model -> Html Msg
view_exception model =
    div [ id "exception" ]
        [ Html.text
            (case model.exception of
                Just exp ->
                    exp.error_msg

                _ ->
                    ""
            )
        ]


view_nav : Model -> List (Html Msg) -> Html Msg
view_nav model content =
    div [ id "nav" ]
        (content
            ++ (if Flashcard.Model.hasException model then
                    [ view_exception model ]

                else
                    []
               )
        )


view_review_and_answer_nav : Model -> Html Msg
view_review_and_answer_nav model =
    view_nav model <|
        [ view_mode model
        ]
            ++ (if Flashcard.Model.inReview model then
                    [ view_next_nav model ]

                else
                    []
               )


view_review_nav : Model -> Html Msg
view_review_nav model =
    view_nav model <|
        [ view_mode model
        ]
            ++ (if Flashcard.Model.inReview model then
                    [ view_prev_nav model, view_next_nav model ]

                else
                    []
               )


view_example : Model -> Flashcard -> Html Msg
view_example _ card =
    div [ id "example" ]
        [ div [] [ Html.text "e.g., " ]
        , div [ id "sentence" ] [ Html.text (Flashcard.Model.example card) ]
        ]


view_phrase : Model -> Flashcard -> Html Msg
view_phrase _ card =
    div [ id "phrase" ] [ Html.text (Flashcard.Model.translationOrPhrase card) ]


view_review_only_card : Model -> Flashcard -> Html Msg
view_review_only_card model card =
    view_card model
        card
        Nothing
        (Just [ onDoubleClick ReviewAnswer ])
        [ view_phrase model card
        , view_example model card
        ]


view_reviewed_only_card : Model -> Flashcard -> Html Msg
view_reviewed_only_card model card =
    view_card model
        card
        (Just [ ( "flip", True ) ])
        Nothing
        [ view_phrase model card
        , view_example model card
        ]


view_input_answer : Model -> Flashcard -> Html Msg
view_input_answer _ _ =
    div [ id "answer_input", Util.onEnterUp SubmitAnswer ]
        [ Html.input [ onInput InputAnswer, attribute "placeholder" "Type an answer.." ] []
        , div [ id "submit" ]
            [ div [ id "button", onClick SubmitAnswer ] [ Html.text "Submit" ]
            ]
        ]


view_quality : Model -> Flashcard -> Int -> Html Msg
view_quality model _ q =
    let
        selected =
            case model.selected_quality of
                Just quality ->
                    quality == q

                Nothing ->
                    False
    in
    div [ classList [ ( "choice", True ), ( "select", selected ) ], onClick (RateQuality q) ] <|
        [ Html.text (String.fromInt q)
        ]
            ++ (if q == 0 then
                    [ Html.text " - most difficult" ]

                else if q == 5 then
                    [ Html.text " - easiest" ]

                else
                    []
               )


view_rate_answer : Model -> Flashcard -> Html Msg
view_rate_answer model card =
    div [ id "answer-quality" ]
        [ Html.text """Rate the difficulty of this card."""
        , div [ id "choices" ] (List.map (view_quality model card) (List.range 0 5))
        ]


view_rated_card : Model -> Flashcard -> Html Msg
view_rated_card model card =
    let
        rating =
            Maybe.withDefault "none" <| Maybe.map String.fromInt model.selected_quality
    in
    view_card model
        card
        Nothing
        Nothing
        [ view_phrase model card
        , view_example model card
        , div [ id "card_rating" ] [ Html.text ("Rated " ++ rating) ]
        ]


view_reviewed_and_answered_card : Model -> Flashcard -> Bool -> Html Msg
view_reviewed_and_answered_card model card answered_correctly =
    view_card model card (Just [ ( "flip", True ) ]) Nothing <|
        [ view_phrase model card
        , view_example model card
        ]
            ++ (if answered_correctly then
                    [ view_rate_answer model card ]

                else
                    []
               )


view_review_and_answer_card : Model -> Flashcard -> Html Msg
view_review_and_answer_card model card =
    view_card model
        card
        Nothing
        Nothing
        [ view_phrase model card
        , view_example model card
        , view_input_answer model card
        ]


view_card : Model -> Flashcard -> Maybe (List ( String, Bool )) -> Maybe (List (Html.Attribute Msg)) -> List (Html Msg) -> Html Msg
view_card _ _ addl_classes addl_attrs content =
    div
        ([ id "card"
         , classList
            ([ ( "cursor", True ), ( "noselect", True ) ]
                ++ Maybe.withDefault [] addl_classes
            )
         ]
            ++ Maybe.withDefault [] addl_attrs
        )
        content


view_finish_review : Model -> Html Msg
view_finish_review _ =
    div [ id "finished" ]
        [ div [] [ Html.text "You've finished this session.  Great job.  Come back tomorrow!" ]
        ]


view_mode : Model -> Html Msg
view_mode model =
    let
        mode_name =
            case model.mode of
                Just m ->
                    Flashcard.Mode.modeName m

                Nothing ->
                    "None"
    in
    div [ id "mode" ] [ Html.text (mode_name ++ " Mode") ]


view_content : Model -> Html Msg
view_content model =
    let
        content =
            case model.session_state of
                Loading ->
                    [ div [ id "loading" ] [] ]

                Init resp ->
                    [ div [ id "loading" ]
                        [ if List.length resp.flashcards == 0 then
                            Html.text "You do not have any flashcards.  Read some more texts and add flashcards before continuing."

                          else
                            Html.text ""
                        ]
                    ]

                ViewModeChoices choices ->
                    [ view_mode_choices model choices
                    , view_additional_notes model
                    , view_nav model
                        [ view_start_nav model
                        ]
                    ]

                ReviewCard card ->
                    [ view_review_only_card model card
                    , view_review_nav model
                    ]

                ReviewCardAndAnswer card ->
                    [ view_review_and_answer_card model card
                    , view_review_and_answer_nav model
                    ]

                ReviewedCardAndAnsweredCorrectly card ->
                    [ view_reviewed_and_answered_card model card True
                    , view_review_and_answer_nav model
                    ]

                ReviewedCardAndAnsweredIncorrectly card ->
                    [ view_reviewed_and_answered_card model card False
                    , view_review_and_answer_nav model
                    ]

                RatedCard card ->
                    [ view_rated_card model card
                    , view_review_and_answer_nav model
                    ]

                ReviewedCard card ->
                    [ view_reviewed_only_card model card
                    , view_review_nav model
                    ]

                FinishedReview ->
                    [ view_finish_review model
                    ]
    in
    div [ id "flashcard" ]
        [ div [ id "contents" ] content
        ]
