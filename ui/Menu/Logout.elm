module Menu.Logout exposing (..)

import Json.Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required, resolve)


type alias LogOutResp =
    { redirect : String }


logoutRespDecoder : Json.Decode.Decoder LogOutResp
logoutRespDecoder =
    decode LogOutResp
        |> required "redirect" Json.Decode.string
