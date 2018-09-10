module Student.View exposing (..)

import Html exposing (Html, div)
import Html.Attributes exposing (class, classList, attribute)
import Html.Events exposing (onClick)

import Student.Profile exposing (StudentProfile)
import Menu.Msg exposing (Msg(..))


view_student_profile_header : StudentProfile -> (Msg -> msg) -> List (Html msg)
view_student_profile_header student_profile top_level_msg =
  [
    div [classList [("menu_item", True)]] [
      Html.a [attribute "href" ""] [ Html.text "Flashcards" ]
    ]
  , div [classList [("menu_item", True)]] [
      div [class "profile_dropdown_menu"] [
        div [] [ Html.a [attribute "href" "/profile/instructor/"] [
            Html.text (Student.Profile.studentUserName student_profile)
          ]
        ]
      , div [classList [("profile_dropdown_menu_overlay", True)]] [
          div [ class "profile_dropdown_menu_item"
              , onClick (top_level_msg <| (StudentLogout student_profile))
              ] [
            Html.text "Logout"
          ]
        ]
      ]
    ]
  ]
