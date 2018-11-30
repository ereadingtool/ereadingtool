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


view_user_profile_menu_items : Maybe (List (Html msg)) -> List (Html msg)
view_user_profile_menu_items view =
  case view of
    Just profile_view ->
      profile_view

    _ ->
      []

view_menu : Menu.Items.MenuItems -> User.Profile.Profile -> (Menu.Msg.Msg -> msg) -> List (Html msg)
view_menu (Menu.Items.MenuItems menu_items) profile top_level_menu_msg =
     (Array.toList
  <| Array.map (\item ->
       view_menu_item (Menu.Item.selected item) (Menu.Item.uri item) (Menu.Item.linkText item) Nothing
     ) menu_items) ++
     (view_user_profile_menu_items (User.Profile.view_profile_header profile top_level_menu_msg))
