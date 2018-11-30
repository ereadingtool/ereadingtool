module Menu.Item exposing (..)

import Html

import Menu exposing (..)


type MenuItem = MenuItem URI LinkText Selected


selected : MenuItem -> Selected
selected (MenuItem _ _ selected) = selected

uri : MenuItem -> URI
uri (MenuItem uri_str _ _) = uri_str

linkText : MenuItem -> LinkText
linkText (MenuItem _ link_text _) = link_text

setSelected : MenuItem -> Bool -> MenuItem
setSelected (MenuItem uri link_text _) selected =
  MenuItem uri link_text selected
