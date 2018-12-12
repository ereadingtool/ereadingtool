module Menu.View exposing (..)

import Array exposing (Array)

import Html exposing (..)
import Html.Attributes exposing (class, classList, attribute)

import User.Profile

import Menu

import Menu.Items
import Menu.Item

import Menu.Msg

view_menu_item : Menu.Selected -> Menu.URI -> Menu.LinkText -> Maybe (List (Html msg)) -> Html msg
view_menu_item selected uri link_text addl_view =
  div [ classList [("menu_item", True), ("menu_item_selected", selected)] ] <|
  (case addl_view of
          Just view ->
            view

          Nothing ->
            []) ++ [
    Html.a [attribute "href" uri] [ Html.text link_text ]
  ]

view_lower_menu_item : Menu.Selected -> Menu.URI -> Menu.LinkText -> Maybe (List (Html msg)) -> Html msg
view_lower_menu_item selected uri link_text addl_view =
  div [ classList [("lower-menu-item", True), ("lower-menu-item-selected", selected)] ] <|
  (case addl_view of
          Just view ->
            view

          Nothing ->
            []) ++ [
    Html.a [attribute "href" uri] [ Html.text link_text ]
   ]

view_top_menu : Menu.Items.MenuItems -> User.Profile.Profile -> (Menu.Msg.Msg -> msg) -> List (Html msg)
view_top_menu (Menu.Items.MenuItems menu_items) profile top_level_menu_msg =
  Maybe.withDefault [] (User.Profile.view_profile_header profile top_level_menu_msg)

view_lower_menu : Menu.Items.MenuItems -> User.Profile.Profile -> (Menu.Msg.Msg -> msg) -> List (Html msg)
view_lower_menu (Menu.Items.MenuItems menu_items) profile top_level_menu_msg =
     (Array.toList
  <| Array.map (\item ->
       view_lower_menu_item (Menu.Item.selected item) (Menu.Item.uri item) (Menu.Item.linkText item) Nothing
     ) menu_items) ++ Maybe.withDefault [] (User.Profile.view_profile_menu_items profile top_level_menu_msg)
