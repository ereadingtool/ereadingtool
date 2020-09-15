module Viewer exposing (Viewer, cred, decoder, id, role)

import Api exposing (Cred)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Role exposing (Role)


type Viewer
    = Viewer Cred Id Role


decoder : Decoder (Cred -> Id -> Role -> Viewer)
decoder =
    Decode.succeed Viewer


cred : Viewer -> Cred
cred (Viewer val _ _) =
    val


id : Viewer -> Id
id (Viewer _ val _) =
    val


role : Viewer -> Role
role (Viewer _ _ val) =
    val
