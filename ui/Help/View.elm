module Help.View exposing (ArrowPlacement(..), ArrowPosition(..), view_hint_overlay)

import Html exposing (Html, div, span)
import Html.Attributes exposing (id, class, classList, attribute)


type ArrowPosition = ArrowLeft | ArrowRight

type ArrowPlacement = ArrowUp ArrowPosition | ArrowDown ArrowPosition

type alias HelpMsgAttributes msg = {
   id: String
 , visible: Bool
 , text: String
 , cancel_event : Html.Attribute msg
 , next_event : Html.Attribute msg
 , prev_event : Html.Attribute msg
 , addl_attributes : List (Html.Attribute msg)
 , arrow_placement: ArrowPlacement
 }


view_cancel_btn : Html.Attribute msg -> Html msg
view_cancel_btn event_attr =
  Html.img [
      attribute "src" "/static/img/cancel.svg"
    , attribute "height" "13px"
    , attribute "width" "13px"
    , class "cursor"
    , event_attr
    ] []

arrowPlacementToClass : ArrowPlacement -> String
arrowPlacementToClass arrow_placement =
  case arrow_placement of
    ArrowUp pos ->
      case pos of
        ArrowLeft ->
          "hint-up-left"

        ArrowRight ->
          "hint-up-right"

    ArrowDown pos ->
      case pos of
        ArrowLeft ->
          "hint-down-left"

        ArrowRight ->
          "hint-down-right"


view_hint_overlay : HelpMsgAttributes msg -> Html msg
view_hint_overlay {id, visible, text, cancel_event, next_event, prev_event, addl_attributes, arrow_placement} =
  let
    hint_class = arrowPlacementToClass arrow_placement
  in
    span [ Html.Attributes.id id
         , classList [("hint_overlay", True)
         , ("invisible", not visible)]] [
      span ([class hint_class] ++ addl_attributes) [
        span [class "msg"] [ Html.text text ]
      , span [class "exit"] [ view_cancel_btn cancel_event ]
      , span [class "nav"] [
          span [classList [("prev", False), ("cursor", True)], prev_event] [ Html.text "prev" ]
        , span [] [ Html.text " | " ]
        , span [classList [("next", False), ("cursor", True)], next_event] [ Html.text "next" ]
        ]
      ]
    ]