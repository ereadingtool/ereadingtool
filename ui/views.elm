module Views exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, classList, attribute)

import Menu
import Menu.Items
import Menu.Item

import Menu.View

import User.Profile

import Menu.Msg


view_header : List (Html msg) -> Html msg
view_header menu_items =
  div [class "header"] [
    div [] [Html.text "E-Reader"]
  , div [class "menu"] menu_items
  ]

view_unauthed_header : Html msg
view_unauthed_header =
  view_header []

view_authed_header : User.Profile.Profile -> Maybe Menu.SelectedMenuItem -> (Menu.Msg.Msg -> msg) -> Html msg
view_authed_header profile selected_menu_item top_level_menu_msg =
  let
    m_items =
      case selected_menu_item of
        Just selected_index ->
          (Menu.Items.setSelected Menu.Items.menu_items selected_index True)

        _ ->
          Menu.Items.menu_items
  in
    view_header (Menu.View.view_menu m_items profile top_level_menu_msg)

view_filter : Html msg
view_filter = div [classList [("filter_items", True)] ] [
     div [classList [("filter", True)] ] [
         Html.input [attribute "placeholder" "Search texts.."] []
       , Html.a [attribute "href" "/admin/text/"] [Html.text "Create A Text"]
     ]
 ]

view_footer : Html msg
view_footer = div [classList [("footer_items", True)] ] [
    div [classList [("footer", True), ("message", True)] ] [
        Html.text ""
    ]
 ]

view_preview : Html msg
view_preview  =
    div [ classList [("preview", True)] ] [
      div [ classList [("preview_menu", True)] ] [
            span [ classList [("menu_item", True)] ] [
              Html.input [attribute "placeholder" "Search texts.."] []
            ]
      ]
    ]