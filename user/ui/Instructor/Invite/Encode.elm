module Instructor.Invite.Encode exposing (..)

import Json.Encode

import Instructor.Invite exposing (Email)


newInviteEncoder : Email -> Json.Encode.Value
newInviteEncoder email =
  Json.Encode.object [
    ("email", Json.Encode.string (Instructor.Invite.emailToString email))
  ]