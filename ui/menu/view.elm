module Menu.View exposing (..)

import Array exposing (Array)

import Html exposing (..)
import Html.Attributes exposing (class, classList, attribute)

import User.Profile

import Help.PopUp exposing (Help)
import Help.View

import Menu.Items
import Menu.Item

import Menu.Msg


view_menu_item : Menu.Item.MenuItem -> Html msg
view_menu_item menu_item =
  div [ classList [("menu_item", True), ("menu_item_selected", Menu.Item.selected menu_item)] ] [
    Html.a [attribute "href" (Menu.Item.uri menu_item)] [ Html.text (Menu.Item.linkText menu_item) ]
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
  (Array.toList <| Array.map view_menu_item menu_items) ++
  (view_user_profile_menu_items (User.Profile.view_profile_header profile top_level_menu_msg ))
