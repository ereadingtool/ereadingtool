import Html exposing (Html)

import Config exposing (student_login_api_endpoint)
import Flags

import Login


main : Program Flags.UnAuthedFlags Login.Model Login.Msg
main =
  Html.programWithFlags
    { init = Login.init
    , view = (Login.view (Login.student_login "/signup/student" 2))
    , subscriptions = Login.subscriptions
    , update = (Login.update student_login_api_endpoint)
    }
