module Views exposing (view_filter, view_header, view_footer, view_preview, view_menu,
  view_user_profile_menu_item, set_selected)

import Html exposing (..)
import Html.Attributes exposing (classList, attribute)
import Array exposing (Array)

import Profile

type alias Selected = Bool
type alias URI = String
type alias LinkText = String
type alias SelectedMenuItem = Int

type MenuItem = MenuItem URI LinkText Selected

type MenuItems = MenuItems (Array MenuItem)

menu_items : MenuItems
menu_items = MenuItems <| Array.fromList [
    MenuItem "/admin/" "Quizzes" False
  , MenuItem "/login/student/" "Student Login" False
  , MenuItem "/login/instructor/" "Instructor Login" False
  ]

set_selected_menu_item : MenuItem -> Bool -> MenuItem
set_selected_menu_item (MenuItem uri link_text selected) select =
  MenuItem uri link_text select

set_selected : MenuItems -> Int -> Bool -> MenuItems
set_selected (MenuItems menu_items) index select =
  case Array.get index menu_items of
    Just menu_item -> MenuItems (Array.set index (set_selected_menu_item menu_item select) menu_items)
    _ -> MenuItems menu_items

view_menu_item : MenuItem -> Html msg
view_menu_item (MenuItem uri link_text selected) =
  span [ classList [("menu_item", True), ("menu_item_selected", selected)] ]
    [ Html.a [attribute "href" uri] [ Html.text link_text ] ]

view_user_profile_menu_item : Maybe (List (Html msg)) -> List (Html msg)
view_user_profile_menu_item view =
  case view of
    Just profile_view -> [ span [ classList [("menu_item", True)] ] profile_view ]
    _ -> []

view_menu : MenuItems -> Profile.Profile -> List (Html msg)
view_menu (MenuItems menu_items) profile =
  (Array.toList <| Array.map view_menu_item menu_items) ++
  view_user_profile_menu_item (Profile.view_profile_header profile)

view_header : Profile.Profile -> Maybe SelectedMenuItem -> Html msg
view_header profile selected_menu_item =
  let
    m_items = case selected_menu_item of
      Just selected_index -> (set_selected menu_items selected_index True)
      _ -> menu_items
  in
    div [classList [("header", True)]] [
      text "E-Reader"
    , div [classList [("menu", True)]] (view_menu m_items profile)
    ]

view_filter : Html msg
view_filter = div [classList [("filter_items", True)] ] [
     div [classList [("filter", True)] ] [
         Html.input [attribute "placeholder" "Search texts.."] []
       , Html.a [attribute "href" "/admin/create-quiz"] [Html.text "Create Text"]
     ]
 ]

view_footer : Html msg
view_footer = div [classList [("footer_items", True)] ] [
    div [classList [("footer", True), ("message", True)] ] [
        Html.text ""
    ]
 ]

view_preview : Html msg
view_preview  =
    div [ classList [("preview", True)] ] [
      div [ classList [("preview_menu", True)] ] [
            span [ classList [("menu_item", True)] ] [
                Html.button [] [ Html.text "Preview" ]
              , Html.input [attribute "placeholder" "Search texts.."] []
            ]
      ]
    ]