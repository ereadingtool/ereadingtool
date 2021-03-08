module Menu.Item.Link exposing
    ( MenuItemLink
    , new
    , text
    , uri
    )

import Menu exposing (..)


type MenuItemLink
    = MenuItemLink URI LinkText


new : URI -> LinkText -> MenuItemLink
new u link_text =
    MenuItemLink u link_text


uri : MenuItemLink -> URI
uri (MenuItemLink u _) =
    u


text : MenuItemLink -> LinkText
text (MenuItemLink _ t) =
    t
