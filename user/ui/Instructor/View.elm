module Instructor.View exposing (..)

import Html exposing (Html, div)
import Html.Attributes exposing (id, class, classList, attribute)
import Html.Events exposing (onClick)

import Instructor.Profile exposing (InstructorProfile)
import Menu.Msg exposing (Msg(..))


view_instructor_profile_link : InstructorProfile -> (Msg -> msg) -> Html msg
view_instructor_profile_link instructor_profile top_level_msg =
  div [class "profile_dropdown_menu"] [
    div [] [
      Html.a [attribute "href" (Instructor.Profile.profileUriToString instructor_profile)
    ] [ Html.text (Instructor.Profile.usernameToString (Instructor.Profile.username instructor_profile)) ]
    ]
  , div [classList [("profile_dropdown_menu_overlay", True)]] [
      div [ class "profile_dropdown_menu_item"
          , onClick (top_level_msg <| (InstructorLogout instructor_profile))
          ] [
        Html.text "Logout"
      ]
    ]
  ]

view_instructor_profile_header : InstructorProfile -> (Msg -> msg) -> List (Html msg)
view_instructor_profile_header instructor_profile top_level_msg =
  [
    div [id "profile-link", classList [("menu_item", True)]] [
      view_instructor_profile_link instructor_profile top_level_msg
    ]
  ]
