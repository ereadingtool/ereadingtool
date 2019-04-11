module Menu.View exposing (..)

import Array exposing (Array)

import Html exposing (..)
import Html.Attributes exposing (class, classList, attribute)

import User.Profile

import Menu.Items
import Menu.Item

import Menu.Msg


view_menu_item : Menu.Item.MenuItem -> Maybe (List (Html msg)) -> Html msg
view_menu_item menu_item addl_view =
  div [ classList [("menu_item", True), ("menu_item_selected", Menu.Item.selected menu_item)] ] <|
  (case addl_view of
          Just view ->
            view

          Nothing ->
            []) ++ [
    Html.a [attribute "href" (Menu.Item.uriToString menu_item)] [ Html.text (Menu.Item.linkTextToString menu_item) ]
  ]

view_lower_menu_item : Menu.Item.MenuItem -> Maybe (List (Html msg)) -> Html msg
view_lower_menu_item menu_item addl_view =
  div [ classList [("lower-menu-item", True), ("lower-menu-item-selected", Menu.Item.selected menu_item)] ] <|
  (case addl_view of
          Just view ->
            view

          Nothing ->
            []) ++ [
    Html.a [attribute "href" (Menu.Item.uriToString menu_item)] [ Html.text (Menu.Item.linkTextToString menu_item) ]
   ]

view_top_menu : Menu.Items.MenuItems -> User.Profile.Profile -> (Menu.Msg.Msg -> msg) -> List (Html msg)
view_top_menu (Menu.Items.MenuItems menu_items) profile top_level_menu_msg =
  Maybe.withDefault [] (User.Profile.view_profile_header profile top_level_menu_msg)

view_lower_menu : Menu.Items.MenuItems -> User.Profile.Profile -> (Menu.Msg.Msg -> msg) -> List (Html msg)
view_lower_menu (Menu.Items.MenuItems menu_items) profile top_level_menu_msg =
     (Array.toList
  <| Array.map (\item ->
       view_lower_menu_item item Nothing
     ) menu_items) ++ Maybe.withDefault [] (User.Profile.view_profile_menu_items profile top_level_menu_msg)
