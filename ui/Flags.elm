module Flags exposing (..)

import Menu.Items

type alias CSRFToken = String

type alias UnAuthedFlags a = { a |
    csrftoken : CSRFToken }


type alias AuthedFlags a = { a |
   csrftoken : CSRFToken
 , menu_items : List Menu.Items.MenuItemParams }
