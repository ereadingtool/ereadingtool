import Html exposing (Html)

import Config
import Flags

import Login


main : Program Flags.UnAuthedFlags Login.Model Login.Msg
main =
  Html.programWithFlags
    { init = Login.init
    , view = (Login.view (Login.student_login Config.student_signup_page Config.student_login_page 2))
    , subscriptions = Login.subscriptions
    , update = (Login.update Config.student_login_api_endpoint)
    }
