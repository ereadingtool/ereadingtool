module Menu.View exposing
    ( view_lower_menu
    , view_lower_menu_item
    , view_top_menu
    )

import Array exposing (Array)
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList)
import Menu.Item
import Menu.Items
import Menu.Msg
import User.Profile


view_menu_item : Menu.Item.MenuItem -> Maybe (List (Html msg)) -> Html msg
view_menu_item menu_item addl_view =
    div [ classList [ ( "menu_item", True ), ( "menu_item_selected", Menu.Item.selected menu_item ) ] ] <|
        (case addl_view of
            Just view ->
                view

            Nothing ->
                []
        )
            ++ [ Html.a [ attribute "href" (Menu.Item.uriToString menu_item) ] [ Html.text (Menu.Item.linkTextToString menu_item) ]
               ]


view_lower_menu_item : Menu.Item.MenuItem -> Maybe (List (Html msg)) -> Html msg
view_lower_menu_item menu_item addl_view =
    div [ classList [ ( "lower-menu-item", True ), ( "lower-menu-item-selected", Menu.Item.selected menu_item ) ] ] <|
        (case addl_view of
            Just view ->
                view

            Nothing ->
                []
        )
            ++ [ Html.a [ attribute "href" (Menu.Item.uriToString menu_item) ] [ Html.text (Menu.Item.linkTextToString menu_item) ]
               ]


view_top_menu : Menu.Items.MenuItems -> User.Profile.Profile -> (Menu.Msg.Msg -> msg) -> List (Html msg)
view_top_menu (Menu.Items.MenuItems menu_items) profile top_level_menu_msg =
    Maybe.withDefault [] (User.Profile.view_profile_header profile top_level_menu_msg)


view_lower_menu : Menu.Items.MenuItems -> User.Profile.Profile -> (Menu.Msg.Msg -> msg) -> List (Html msg)
view_lower_menu (Menu.Items.MenuItems menu_items) profile top_level_menu_msg =
    Array.toList <|
        Array.map
            (\item ->
                view_lower_menu_item item Nothing
            )
            menu_items
