module Viewer exposing (Viewer, cred, decoder)

import Api exposing (Cred)
import Json.Decode as Decode exposing (Decoder)


type Viewer
    = Viewer Cred


decoder : Decoder (Cred -> Viewer)
decoder =
    Decode.succeed Viewer


cred : Viewer -> Cred
cred (Viewer val) =
    val
