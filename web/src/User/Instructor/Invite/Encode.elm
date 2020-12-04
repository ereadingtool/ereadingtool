module User.Instructor.Invite.Encode exposing (newInviteEncoder)

import Json.Encode
import User.Instructor.Invite as InstructorInvite exposing (Email)


newInviteEncoder : Email -> Json.Encode.Value
newInviteEncoder email =
    Json.Encode.object
        [ ( "email", Json.Encode.string (InstructorInvite.emailToString email) )
        ]
