import Html exposing (Html, div, span)
import Html.Attributes exposing (id, class, classList, attribute)

import Dict exposing (Dict)

import User.Profile

import Views

import Student.Profile exposing (StudentProfileParams)

import Student.Profile.Msg exposing (..)
import Student.Profile.Flags exposing (Flags)
import Student.Profile.Update
import Student.Profile.Model exposing (Model)
import Student.Profile.View

import Student.Profile.Help


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
    , Student.Profile.View.view_feedback_links model
    , Student.Profile.View.view_flashcards model
    , (if not (String.isEmpty model.err_str) then
        span [attribute "class" "error"] [ Html.text "error: ", Html.text model.err_str ]
       else Html.text "")
    ]
  ]

-- VIEW
view : Model -> Html Msg
view model =
  div [] [
    Student.Profile.View.view_header model Logout {next=NextHelp, prev=PrevHelp, close=CloseHelp}
  , view_content model
  , Views.view_footer
  ]
