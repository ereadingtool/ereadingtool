module Instructor.Invite.Decode exposing (..)

import Instructor.Invite exposing (Email, InstructorInvite)
import Json.Decode


newInviteRespDecoder : Json.Decode.Decoder Instructor.Invite.InstructorInvite
newInviteRespDecoder =
    Json.Decode.map3 Instructor.Invite.InstructorInvite
        (Json.Decode.field "email" (Json.Decode.map Instructor.Invite.Email Json.Decode.string))
        (Json.Decode.field "invite_code" (Json.Decode.map Instructor.Invite.InviteCode Json.Decode.string))
        (Json.Decode.field "expiration" (Json.Decode.map Instructor.Invite.InviteExpiration Json.Decode.string))
