module Menu.Logout exposing
    ( LogOutResp
    , logoutRespDecoder
    )

import Json.Decode
import Json.Decode.Pipeline exposing (required)


type alias LogOutResp =
    { redirect : String }


logoutRespDecoder : Json.Decode.Decoder LogOutResp
logoutRespDecoder =
    Json.Decode.succeed LogOutResp
        |> required "redirect" Json.Decode.string
