import Html exposing (Html)

import Config exposing (instructor_login_api_endpoint)
import Flags

import Login


main : Program Flags.UnAuthedFlags Login.Model Login.Msg
main =
  Html.programWithFlags
    { init = Login.init
    , view = (Login.view "/signup/instructor")
    , subscriptions = Login.subscriptions
    , update = (Login.update instructor_login_api_endpoint)
    }