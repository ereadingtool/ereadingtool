module Id exposing (Id, decoder, id)

import Json.Decode as Decode exposing (Decoder)


type Id
    = Id Int


id : Id -> Int
id (Id val) =
    val


decoder : Decoder Id
decoder =
    Decode.map Id Decode.int
