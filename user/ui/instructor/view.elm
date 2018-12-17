module Instructor.View exposing (..)

import Html exposing (Html, div)
import Html.Attributes exposing (id, class, classList, attribute)
import Html.Events exposing (onClick)

import Instructor.Profile exposing (InstructorProfile)
import Menu.Msg exposing (Msg(..))

import Config


view_instructor_profile_link : InstructorProfile -> (Msg -> msg) -> Html msg
view_instructor_profile_link instructor_profile top_level_msg =
  div [class "profile_dropdown_menu"] [
    div [] [ Html.a [attribute "href" Config.instructor_profile_page] [
      Html.text (Instructor.Profile.attrs instructor_profile).username ]
    ]
  , div [classList [("profile_dropdown_menu_overlay", True)]] [
      div [ class "profile_dropdown_menu_item"
          , onClick (top_level_msg <| (InstructorLogout instructor_profile))
          ] [
        Html.text "Logout"
      ]
    ]
  ]

view_instructor_profile_menu_items : InstructorProfile -> (Msg -> msg) -> List (Html msg)
view_instructor_profile_menu_items instructor_profile top_level_msg =
 [
   div [classList [("lower-menu-item", True)]] [
      Html.a [attribute "href" "/admin/texts/"] [ Html.text "Texts" ]
   ]
 , div [classList [("lower-menu-item", True)]] [
      Html.a [attribute "href" "/admin/text/"] [ Html.text "Create A Text" ]
   ]
 ]

view_instructor_profile_header : InstructorProfile -> (Msg -> msg) -> List (Html msg)
view_instructor_profile_header instructor_profile top_level_msg =
  [
    div [id "profile-link", classList [("menu_item", True)]] [
      view_instructor_profile_link instructor_profile top_level_msg
    ]
  ]
