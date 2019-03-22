module Flashcard.View exposing (..)


import Html exposing (Html, div, span)
import Html.Attributes exposing (id, class, classList, attribute, property)
import Html.Events exposing (onClick, onDoubleClick, onMouseLeave)

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

view_nav : List (Html Msg) -> Html Msg
view_nav content =
  div [id "nav"] content


view_card : Model -> Flashcard -> Html Msg
view_card model card =
  div [id "card", class "cursor"] [
    Html.text (Flashcard.Model.phrase card)
  , Html.text (Flashcard.Model.example card)
  ]

view_content : Model -> Html Msg
view_content model =
  let
    content =
      (case model.session_state of
        Loading ->
          [ div [id "loading"] [
              Html.text ""
            ]
          ]

        Init resp ->
          [ div [id "loading"] [
              (if (List.length resp.flashcards) == 0 then
                Html.text "You do not have any flashcards.  Read some more texts and add flashcards before continuing."
               else
                Html.text "An error has occurred.")
            ]
          ]

        ViewModeChoices choices ->
          [ view_mode_choices model choices
          , view_nav [
              view_start_nav model
            ]
          ]

        ReviewCard card ->
          [ view_card model card
          , view_nav [

            ]
          ]

        ReviewCardAndAnswer card ->
          [ view_card model card
          , view_nav [

            ]
          ])
  in
    div [id "flashcard"] [
      div [id "content"] content
    ]