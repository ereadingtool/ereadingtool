module Instructor.View exposing (..)

import Html exposing (Html, div)
import Html.Attributes exposing (class, classList, attribute)
import Html.Events exposing (onClick)

import Instructor.Profile exposing (InstructorProfile)
import Menu.Msg exposing (Msg(..))


view_instructor_profile_header : InstructorProfile -> (Msg -> msg) -> List (Html msg)
view_instructor_profile_header instructor_profile top_level_msg =
  [
    div [classList [("menu_item", True)]] [
      Html.a [attribute "href" "/admin/texts/"] [ Html.text "Texts" ]
    ]
  , div [classList [("menu_item", True)]] [
      div [class "profile_dropdown_menu"] [
        div [] [ Html.a [attribute "href" "/profile/instructor/"] [
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
    ]
  ]
