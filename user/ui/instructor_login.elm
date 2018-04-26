import Html exposing (Html)

import Config exposing (instructor_login_api_endpoint)
import Flags exposing (CSRFToken, Flags)

import Login exposing (init, view, subscriptions, update)


main : Program Flags Login.Model Login.Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = (update instructor_login_api_endpoint)
    }
