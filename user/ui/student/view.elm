module Student.View exposing (..)

import Html exposing (Html, div)
import Html.Attributes exposing (class, classList, attribute)
import Html.Events exposing (onClick)

import Student.Profile
import Menu.Msg exposing (Msg(..))

import Config


view_flashcard_menu_item : Student.Profile.StudentProfile -> (Msg -> msg) -> Html msg
view_flashcard_menu_item student_profile top_level_msg =
  div [classList [("menu_item", True)]] [
      Html.a [attribute "href" ""] [ Html.text "Flashcards" ]
  ]

view_student_profile_page_link : Student.Profile.StudentProfile -> (Msg -> msg) -> Html msg
view_student_profile_page_link student_profile top_level_msg =
  div [] [
    Html.a [attribute "href" Config.student_profile_page] [
      Html.text (Student.Profile.studentUserName student_profile)
    ]
  ]

view_student_profile_logout_link : Student.Profile.StudentProfile -> (Msg -> msg) -> Html msg
view_student_profile_logout_link student_profile top_level_msg =
  div [classList [("profile_dropdown_menu_overlay", True)]] [
    div [class "profile_dropdown_menu_item", onClick (top_level_msg <| (StudentLogout student_profile))] [
      Html.text "Logout"
    ]
  ]

view_profile_dropdown_menu : Student.Profile.StudentProfile -> (Msg -> msg) -> List (Html msg) -> Html msg
view_profile_dropdown_menu student_profile top_level_msg items =
  div [classList [("menu_item", True)]] [
    div [class "profile_dropdown_menu"] items
  ]

view_student_profile_header : Student.Profile.StudentProfile -> (Msg -> msg) -> List (Html msg)
view_student_profile_header student_profile top_level_msg =
  let
    items = [
      view_student_profile_page_link student_profile top_level_msg
    , view_student_profile_logout_link student_profile top_level_msg
    ]
  in [
    view_flashcard_menu_item student_profile top_level_msg
  , view_profile_dropdown_menu student_profile top_level_msg items
  ]
