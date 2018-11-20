import Html exposing (Html)

import Config
import Flags

import Login
import Html exposing (Html, div, span)
import Html.Attributes exposing (class, classList, attribute)

import Views


view_help_msgs : Login.Login -> Login.Model -> List (Html Login.Msg)
view_help_msgs login model =
  [div [class "help_msgs"] [
    Html.text """When signing in, please note that this website is not connected to your university’s user account.
    If this is your first time using this website, please create a new account."""
  ]]

view_content : Login.Login -> Login.Model -> Html Login.Msg
view_content login model =
  div [ classList [("login", True)] ] [
    div [class "login_type"] [ Html.text (Login.label login) ]
  , div [classList [("login_box", True)] ] <|
      (Login.view_email_input model) ++
      (Login.view_password_input model) ++ (Login.view_login login) ++
      (Login.view_submit model) ++
      (view_help_msgs login model) ++
      (Login.view_errors model)
  ]

view : Login.Login -> Login.Model -> Html Login.Msg
view login model =
  div [] [
    Views.view_unauthed_header
  , view_content login model
  , Views.view_footer
  ]


main : Program Flags.UnAuthedFlags Login.Model Login.Msg
main =
  Html.programWithFlags
    { init = Login.init
    , view = view (Login.student_login Config.student_signup_page Config.student_login_page 2)
    , subscriptions = Login.subscriptions
    , update = (Login.update Config.student_login_api_endpoint)
    }
