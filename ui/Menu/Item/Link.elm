module Menu.Item.Link exposing (..)

import Menu exposing (..)


type MenuItemLink
    = MenuItemLink URI LinkText


new : URI -> LinkText -> MenuItemLink
new uri link_text =
    MenuItemLink uri link_text


uri : MenuItemLink -> URI
uri (MenuItemLink uri _) =
    uri


text : MenuItemLink -> LinkText
text (MenuItemLink _ text) =
    text
