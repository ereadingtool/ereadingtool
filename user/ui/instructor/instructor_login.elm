import Html exposing (Html)

import Config
import User.Flags.UnAuthed exposing (UnAuthedUserFlags)

import Login


main : Program UnAuthedUserFlags Login.Model Login.Msg
main =
  Html.programWithFlags
    { init = Login.init
    , view = Login.view
    , subscriptions = Login.subscriptions
    , update = Login.update
    }
