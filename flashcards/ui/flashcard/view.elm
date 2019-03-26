module Flashcard.View exposing (..)


import Html exposing (Html, div, span)
import Html.Attributes exposing (id, class, classList, attribute, property)
import Html.Events exposing (onClick, onDoubleClick, onMouseLeave, onMouseEnter)

import Flashcard.Model exposing (..)
import Flashcard.Msg exposing (Msg(..))

import Flashcard.Mode


view_mode_choice : Model -> Flashcard.Mode.ModeChoiceDesc -> Html Msg
view_mode_choice model choice =
  div [ classList [("mode-choice", True), ("cursor", True), ("selected", choice.selected)]
      , onClick (SelectMode choice.mode)] [
     div [class "name"] [ Html.text (Flashcard.Mode.modeName choice.mode) ]
  ,  div [class "desc"] [ Html.text choice.desc ]
  ,  div [class "select"] [
       Html.img [
          attribute "src" "/static/img/circle_check.svg"
        , attribute "height" "40px"
        , attribute "width" "50px"] []
     ]
  ]

view_mode_choices : Model -> List Flashcard.Mode.ModeChoiceDesc -> Html Msg
view_mode_choices model mode_choices =
  div [id "mode-choices"] (List.map (view_mode_choice model) mode_choices)


view_start_nav : Model -> Html Msg
view_start_nav model =
  div [id "start", class "cursor", onClick Start] [
    Html.text "Start"
  ]

view_next_nav : Model -> Html Msg
view_next_nav model =
  div [id "next", class "cursor", onClick Next] [
    Html.text "Next Card"
  ]

view_nav : List (Html Msg) -> Html Msg
view_nav content =
  div [id "nav"] content

view_review_only_card : Model -> Flashcard -> Html Msg
view_review_only_card model flashcard =
  view_card model flashcard (Just [onDoubleClick ReviewAnswer])

view_review_and_answer_card : Model -> Flashcard -> Html Msg
view_review_and_answer_card model flashcard =
  view_card model flashcard Nothing

view_card : Model -> Flashcard -> Maybe (List (Html.Attribute Msg)) -> Html Msg
view_card model card evts =
  let
    has_tr = Flashcard.Model.hasTranslation card
  in
    div ([id "card", classList [("cursor", True), ("flip", has_tr)]] ++ Maybe.withDefault [] evts) [
      div [id "phrase"] [ Html.text (Flashcard.Model.translationOrPhrase card) ]
    , div [id "example"] [
        div [] [ Html.text "e.g., " ]
      , div [id "sentence"] [ Html.text (Flashcard.Model.example card) ]
      ]
    ]

view_state : SessionState -> Html Msg
view_state session_state =
  div [id "state"] [ Html.text (toString session_state) ]

view_mode : Model -> Html Msg
view_mode model =
  let
    mode_name =
      (case model.mode of
         Just m ->
           Flashcard.Mode.modeName m

         Nothing ->
           "None")
  in
    div [class "mode"] [ Html.text ("Mode: " ++ mode_name) ]

view_content : Model -> Html Msg
view_content model =
  let
    content =
      (case model.session_state of
        Loading -> [div [id "loading"] []]

        Init resp -> [
          div [id "loading"] [
            (if (List.length resp.flashcards) == 0 then
               Html.text "You do not have any flashcards.  Read some more texts and add flashcards before continuing."
             else
               Html.text "") ]
          ]

        ViewModeChoices choices -> [
            view_mode_choices model choices
          , view_nav [
                view_start_nav model
            ]
          ]

        ReviewCard card -> [
            view_review_only_card model card
          , view_nav [
              view_mode model
            , view_state model.session_state
            , view_next_nav model
            ]
          ]


        ReviewCardAndAnswer card -> [
            view_review_and_answer_card model card
          , view_nav [
              view_mode model
            , view_state model.session_state
            , view_nav [
                view_next_nav model
              ]
            ]
          ]

        ReviewedCard card -> [
            view_review_and_answer_card model card
          , view_nav [
              view_mode model
            , view_state model.session_state
            , view_next_nav model
            ]
          ])
  in
    div [id "flashcard"] [
      div [id "content"] content
    ]