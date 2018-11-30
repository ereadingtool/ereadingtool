module Menu.Items exposing (..)

import Array exposing (Array)

import Menu.Item exposing (MenuItem(..))


type MenuItems = MenuItems (Array MenuItem)

menu_items : MenuItems
menu_items =
  MenuItems <| Array.fromList [
    MenuItem "/text/search" "Search Texts" False
  ]

items : MenuItems -> Array MenuItem
items (MenuItems menu_items) =
  menu_items

getItem : MenuItems -> Int -> Maybe MenuItem
getItem (MenuItems items) index =
  Array.get index items

setItem : MenuItems -> MenuItem -> Int -> MenuItems
setItem (MenuItems items) item index =
  MenuItems (Array.set index item items)

setSelected : MenuItems -> Int -> Bool -> MenuItems
setSelected (MenuItems menu_items) index select =
  case Array.get index menu_items of
    Just menu_item ->
      MenuItems (Array.set index (Menu.Item.setSelected menu_item select) menu_items)

    _ ->
      MenuItems menu_items