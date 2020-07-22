module Viewer exposing (Viewer, cred, decoder, role)

import Api exposing (Cred)
import Json.Decode as Decode exposing (Decoder)
import Role exposing (Role)


type Viewer
    = Viewer Cred Role


decoder : Decoder (Cred -> Role -> Viewer)
decoder =
    Decode.succeed Viewer


cred : Viewer -> Cred
cred (Viewer val _) =
    val


role : Viewer -> Role
role (Viewer _ val) =
    val
