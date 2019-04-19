import Html exposing (Html)

import User.Flags.UnAuthed exposing (UnAuthedUserFlags)

import Login
import Html exposing (Html, div, span)
import Html.Attributes exposing (class, classList, attribute)

import Views


type alias Flags = UnAuthedUserFlags {}


view_help_msgs : Login.Model -> List (Html Login.Msg)
view_help_msgs model =
  [div [class "help_msgs"] [
    Html.text """When signing in, please note that this website is not connected to your university’s user account.
    If this is your first time using this website, please create a new account."""
  ]]

view_content : Login.Model -> Html Login.Msg
view_content model =
  div [ classList [("login", True)] ] [
    div [class "login_type"] [ Html.text (Login.label model.login) ]
  , div [classList [("login_box", True)] ] <|
      (Login.view_email_input model) ++
      (Login.view_password_input model) ++ (Login.view_login model.login) ++
      (Login.view_submit model) ++
      (view_help_msgs model) ++
      (Login.view_errors model)
  ]

view : Login.Model -> Html Login.Msg
view model =
  div [] [
    Views.view_unauthed_header
  , view_content model
  , Views.view_footer
  ]


main : Program Flags Login.Model Login.Msg
main =
  Html.programWithFlags
    { init = Login.init
    , view = view
    , subscriptions = Login.subscriptions
    , update = Login.update
    }
