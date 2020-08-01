module User.Instructor.Instructor_Login exposing (Flags, main)

import Browser
import User.Login as Login
import User.User.Flags.UnAuthed exposing (UnAuthedUserFlags)


type alias Flags =
    UnAuthedUserFlags {}


main : Program Flags Login.Model Login.Msg
main =
    Browser.element
        { init = Login.init
        , view = Login.view
        , subscriptions = Login.subscriptions
        , update = Login.update
        }
