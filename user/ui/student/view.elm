module Student.View exposing (..)

import Html exposing (Html, div)
import Html.Attributes exposing (class, classList, attribute)

import Student.Profile exposing (StudentProfile)
import Menu.Msg exposing (Msg(..))


view_student_profile_header : StudentProfile -> (Msg -> msg) -> List (Html msg)
view_student_profile_header student_profile top_level_msg =
  [
    div [classList [("menu_item", True)]] [
      Html.a [attribute "href" ""] [ Html.text "Flashcards" ]
    ]
  , div [classList [("profile_menu_item", True)]] [
      Html.a [attribute "href" "/profile/student/"] [ Html.text (Student.Profile.studentUserName student_profile) ]
    ]
  ]
