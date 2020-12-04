module User.Instructor.Invite.Decode exposing (newInviteRespDecoder)

import Json.Decode
import User.Instructor.Invite as InstructorInvite


newInviteRespDecoder : Json.Decode.Decoder InstructorInvite.InstructorInvite
newInviteRespDecoder =
    Json.Decode.map3 InstructorInvite.InstructorInvite
        (Json.Decode.field "email" (Json.Decode.map InstructorInvite.Email Json.Decode.string))
        (Json.Decode.field "invite_code" (Json.Decode.map InstructorInvite.InviteCode Json.Decode.string))
        (Json.Decode.field "expiration" (Json.Decode.map InstructorInvite.InviteExpiration Json.Decode.string))
