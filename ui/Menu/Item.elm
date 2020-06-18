module Menu.Item exposing (..)

import Menu exposing (..)
import Menu.Item.Link


type MenuItem
    = MenuItem Menu.Item.Link.MenuItemLink Select


new : Menu.Item.Link.MenuItemLink -> Select -> MenuItem
new link select =
    MenuItem link select


selected : MenuItem -> Bool
selected (MenuItem _ is_selected) =
    Menu.selected is_selected


uri : MenuItem -> URI
uri (MenuItem link _) =
    Menu.Item.Link.uri link


uriToString : MenuItem -> String
uriToString menu_item =
    Menu.uriToString (uri menu_item)


linkText : MenuItem -> LinkText
linkText (MenuItem link _) =
    Menu.Item.Link.text link


linkTextToString : MenuItem -> String
linkTextToString menu_item =
    Menu.linkTextToString (linkText menu_item)


setSelected : MenuItem -> Bool -> MenuItem
setSelected (MenuItem link _) select =
    MenuItem link (Select select)
