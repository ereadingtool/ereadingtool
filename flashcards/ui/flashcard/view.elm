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

view_exception : Model -> Html Msg
view_exception model =
  div [id "exception"] [
    Html.text
      (case model.exception of
        Just exp ->
          exp.error_msg

        _ -> "")
  ]

view_nav : Model -> List (Html Msg) -> Html Msg
view_nav model content =
  div [id "nav"] (content ++ (if Flashcard.Model.hasException model then [view_exception model] else []))

view_example : Model -> Flashcard -> Html Msg
view_example model card =
  div [id "example"] [
    div [] [ Html.text "e.g., " ]
  , div [id "sentence"] [ Html.text (Flashcard.Model.example card) ]
  ]

view_phrase : Model -> Flashcard -> Html Msg
view_phrase model card =
  div [id "phrase"] [ Html.text (Flashcard.Model.translationOrPhrase card) ]

view_review_only_card : Model -> Flashcard -> Html Msg
view_review_only_card model card =
  view_card model card (Just [onDoubleClick ReviewAnswer]) [
    view_phrase model card
  , view_example model card
  ]

view_input_answer : Model -> Flashcard -> Html Msg
view_input_answer model card =
  div [id "answer_input"] [
    Html.input [attribute "placeholder" "Type an answer.."] []
  , div [id "submit"] [ div [id "button"] [ Html.text "Submit" ] ]
  ]

view_review_and_answer_card : Model -> Flashcard -> Html Msg
view_review_and_answer_card model card =
  view_card model card Nothing [
    view_phrase model card
  , view_example model card
  , view_input_answer model card
  ]

view_card : Model -> Flashcard -> Maybe (List (Html.Attribute Msg)) -> List (Html Msg) -> Html Msg
view_card model card evts content =
  let
    has_tr = Flashcard.Model.hasTranslation card
  in
    div ([id "card", classList [("cursor", True), ("flip", has_tr)]] ++ Maybe.withDefault [] evts) content

view_finish_review : Model -> Html Msg
view_finish_review model =
  div [id "finished"] [
    div [] [ Html.text "You've finished this session.  Great job.  Come back tomorrow!"]
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
          , view_nav model [
                view_start_nav model
            ]
          ]

        ReviewCard card -> [
            view_review_only_card model card
          , view_nav model [
              view_mode model
            , view_state model.session_state
            , view_next_nav model
            ]
          ]

        ReviewCardAndAnswer card -> [
            view_review_and_answer_card model card
          , view_nav model [
              view_mode model
            , view_state model.session_state
            , view_next_nav model
            ]
          ]

        ReviewedCard card -> [
            view_review_and_answer_card model card
          , view_nav model [
              view_mode model
            , view_state model.session_state
            , view_next_nav model
            ]
          ]

        FinishedReview -> [
          view_finish_review model
          , view_nav model [
              view_mode model
            , view_state model.session_state
          ]])
  in
    div [id "flashcard"] [
      div [id "content"] content
    ]