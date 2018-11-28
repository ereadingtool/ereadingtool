import Html exposing (Html, div, span)
import Html.Attributes exposing (id, class, classList, attribute)

import Array exposing (Array)
import Dict exposing (Dict)

import Config

import User.Profile

import Views
import Student.View

import Student.Profile exposing (StudentProfileParams)

import Student.Profile.Msg exposing (..)
import Student.Profile.Flags exposing (Flags)
import Student.Profile.Update
import Student.Profile.Model exposing (Model)
import Student.Profile.View

import Student.Profile.Help

import Menu.Msg


init : Flags -> (Model, Cmd Msg)
init flags =
  let
    student_help = Student.Profile.Help.init
  in
    ({
      flags = { flags | welcome = True }
    , profile = Student.Profile.emptyStudentProfile
    , editing = Dict.empty
    , username_update = {username = "", valid = Nothing, msg = Nothing}
    , help = student_help
    , err_str = "", errors = Dict.empty
    }
    , Cmd.batch [
        User.Profile.retrieve_student_profile RetrieveStudentProfile flags.profile_id
      , Student.Profile.Help.scrollToFirstMsg student_help
      ])

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = Student.Profile.Update.update
    }


view_content : Model -> Html Msg
view_content model =
  div [ classList [("profile", True)] ] [
    div [classList [("profile_items", True)] ] <|
      (if model.flags.welcome then [Student.Profile.View.view_student_welcome_msg model.profile] else []) ++
    [
      Student.Profile.View.view_preferred_difficulty model
    , Student.Profile.View.view_username model
    , Student.Profile.View.view_user_email model
    , Student.Profile.View.view_student_performance model
    , Student.Profile.View.view_flashcards model
    , (if not (String.isEmpty model.err_str) then
        span [attribute "class" "error"] [ Html.text "error", Html.text model.err_str ]
       else Html.text "")
    ]
  ]

view_student_profile_page_link : Student.Profile.StudentProfile -> (Menu.Msg.Msg -> msg) -> Html msg
view_student_profile_page_link student_profile top_level_msg =
  div [] [
    Html.a [attribute "href" Config.student_profile_page] [
      Html.text (Student.Profile.studentUserName student_profile)
    ]
  ]

view_student_profile_header : Student.Profile.StudentProfile -> (Menu.Msg.Msg -> msg) -> List (Html msg)
view_student_profile_header student_profile top_level_msg = [
    Student.View.view_flashcard_menu_item student_profile top_level_msg
  , Student.View.view_profile_dropdown_menu student_profile top_level_msg [
      view_student_profile_page_link student_profile top_level_msg
    , Student.View.view_student_profile_logout_link student_profile top_level_msg
    ]
  ]

view_profile_header : Student.Profile.StudentProfile -> (Menu.Msg.Msg -> msg) -> Maybe (List (Html msg))
view_profile_header student_profile top_level_msg =
  Just (view_student_profile_header student_profile top_level_msg)

view_menu : Views.MenuItems -> Student.Profile.StudentProfile -> (Menu.Msg.Msg -> msg) -> List (Html msg)
view_menu (Views.MenuItems menu_items) profile top_level_msg =
  (Array.toList <| Array.map Views.view_menu_item menu_items) ++
  (Views.view_user_profile_menu_items (view_profile_header profile top_level_msg))

view_header : Student.Profile.StudentProfile -> (Menu.Msg.Msg -> msg) -> Html msg
view_header student_profile top_level_msg =
  Views.view_header (view_menu Views.menu_items student_profile top_level_msg)

-- VIEW
view : Model -> Html Msg
view model =
  div [] [
    view_header model.profile Logout
  , view_content model
  , Views.view_footer
  ]
