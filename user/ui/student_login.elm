import Html exposing (Html)

import Config exposing (student_login_api_endpoint)
import Flags exposing (CSRFToken, Flags)

import Login exposing (init, view, subscriptions, update)


main : Program Flags Login.Model Login.Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = (update student_login_api_endpoint)
    }
