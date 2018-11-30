module Menu.Item exposing (..)

import Menu exposing (..)

import Student.Profile.Help exposing (StudentHelp)


type MenuItem = MenuItem URI LinkText Selected (Maybe StudentHelp)

selected : MenuItem -> Selected
selected (MenuItem _ _ selected _) = selected

uri : MenuItem -> URI
uri (MenuItem uri_str _ _ _) = uri_str

linkText : MenuItem -> LinkText
linkText (MenuItem _ link_text _ _) = link_text

helpPopUp : MenuItem -> Maybe StudentHelp
helpPopUp (MenuItem _ _ _ popup) = popup

setHelpPopUp : MenuItem -> StudentHelp -> MenuItem
setHelpPopUp (MenuItem uri link_text selected _) help_popup =
  MenuItem uri link_text selected (Just help_popup)

setSelected : MenuItem -> Bool -> MenuItem
setSelected (MenuItem uri link_text _ popup) selected =
  MenuItem uri link_text selected popup
