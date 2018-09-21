import Html exposing (Html)

import Config
import Flags

import Login


main : Program Flags.UnAuthedFlags Login.Model Login.Msg
main =
  Html.programWithFlags
    { init = Login.init
    , view = (Login.view (Login.instructor_login Config.instructor_signup_page Config.instructor_login_page 3))
    , subscriptions = Login.subscriptions
    , update = (Login.update Config.instructor_login_api_endpoint)
    }
