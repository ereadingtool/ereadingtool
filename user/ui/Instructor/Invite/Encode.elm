module Instructor.Invite.Encode exposing (newInviteEncoder)

import Instructor.Invite exposing (Email)
import Json.Encode


newInviteEncoder : Email -> Json.Encode.Value
newInviteEncoder email =
    Json.Encode.object
        [ ( "email", Json.Encode.string (Instructor.Invite.emailToString email) )
        ]
