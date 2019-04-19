import Html exposing (Html)

import User.Flags.UnAuthed exposing (UnAuthedUserFlags)

import Login


type alias Flags = UnAuthedUserFlags {}


main : Program Flags Login.Model Login.Msg
main =
  Html.programWithFlags
    { init = Login.init
    , view = Login.view
    , subscriptions = Login.subscriptions
    , update = Login.update
    }
