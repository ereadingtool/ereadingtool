module User.Flags.UnAuthed exposing (..)

import Flags exposing (UnAuthedFlags)


type alias UnAuthedUserFlags a =
    UnAuthedFlags
        { a
            | user_type : String
            , signup_page_url : String
            , login_uri : String
            , login_page_url : String
            , reset_pass_endpoint : String
            , forgot_pass_endpoint : String
            , forgot_password_url : String
            , acknowledgements_url : String
            , about_url : String
        }
