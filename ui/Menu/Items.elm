module Menu.Items exposing (..)

import Array exposing (Array)
import Menu exposing (..)
import Menu.Item exposing (MenuItem)
import Menu.Item.Link


type MenuItems
    = MenuItems (Array MenuItem)


type alias MenuItemParams =
    { link : String
    , link_text : String
    , selected : Bool
    }


initMenuItemFromParams : MenuItemParams -> MenuItem
initMenuItemFromParams param =
    let
        menu_link =
            Menu.Item.Link.new (Menu.URI param.link) (Menu.LinkText param.link_text)
    in
    Menu.Item.new menu_link (Menu.Select param.selected)


initMenuItems : { a | menu_items : List MenuItemParams } -> MenuItems
initMenuItems flags =
    MenuItems (Array.fromList <| List.map initMenuItemFromParams flags.menu_items)


items : MenuItems -> Array MenuItem
items (MenuItems menu_items) =
    menu_items


getItem : MenuItems -> Int -> Maybe MenuItem
getItem (MenuItems menu_items) index =
    Array.get index menu_items


setItem : MenuItems -> MenuItem -> Int -> MenuItems
setItem (MenuItems menu_items) item index =
    MenuItems (Array.set index item menu_items)


setSelected : MenuItems -> Int -> Bool -> MenuItems
setSelected (MenuItems menu_items) index select =
    case Array.get index menu_items of
        Just menu_item ->
            MenuItems (Array.set index (Menu.Item.setSelected menu_item select) menu_items)

        _ ->
            MenuItems menu_items
