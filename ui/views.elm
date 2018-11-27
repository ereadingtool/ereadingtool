module Views exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, classList, attribute)
import Array exposing (Array)

import User.Profile

import Menu.Msg exposing (Msg)

type alias Selected = Bool
type alias URI = String
type alias LinkText = String
type alias SelectedMenuItem = Int

type MenuItem = MenuItem URI LinkText Selected

type MenuItems = MenuItems (Array MenuItem)

menu_items : MenuItems
menu_items = MenuItems <| Array.fromList [
    MenuItem "/text/search" "Search Texts" False
  ]

set_selected_menu_item : MenuItem -> Bool -> MenuItem
set_selected_menu_item (MenuItem uri link_text selected) select =
  MenuItem uri link_text select

set_selected : MenuItems -> Int -> Bool -> MenuItems
set_selected (MenuItems menu_items) index select =
  case Array.get index menu_items of
    Just menu_item ->
      MenuItems (Array.set index (set_selected_menu_item menu_item select) menu_items)
    _ ->
      MenuItems menu_items

view_menu_item : MenuItem -> Html msg
view_menu_item (MenuItem uri link_text selected) =
  div [ classList [("menu_item", True), ("menu_item_selected", selected)] ] [
    Html.a [attribute "href" uri] [ Html.text link_text ]
  ]

view_user_profile_menu_items : Maybe (List (Html msg)) -> List (Html msg)
view_user_profile_menu_items view =
  case view of
    Just profile_view ->
      profile_view
    _ ->
      []

view_menu : MenuItems -> User.Profile.Profile -> (Msg -> msg) -> List (Html msg)
view_menu (MenuItems menu_items) profile top_level_msg =
  (Array.toList <| Array.map view_menu_item menu_items) ++
  (view_user_profile_menu_items (User.Profile.view_profile_header profile top_level_msg ))

view_unauthed_header : Html msg
view_unauthed_header =
  div [class "header"] [
    div [] [ Html.text "E-Reader" ]
  ]

view_header : User.Profile.Profile -> Maybe SelectedMenuItem -> (Msg -> msg) -> Html msg
view_header profile selected_menu_item top_level_msg =
  let
    m_items =
      case selected_menu_item of
        Just selected_index ->
          (set_selected menu_items selected_index True)
        _ ->
          menu_items
  in
    div [classList [("header", True)]] [
      div [] [ Html.text "E-Reader" ]
    , div [classList [("menu", True)]] (view_menu m_items profile top_level_msg)
    ]

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