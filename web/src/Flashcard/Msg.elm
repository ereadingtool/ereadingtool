module Flashcard.Msg exposing (Msg(..))

import Api.WebSocket as WebSocket
import Flashcard.Mode
import Http
import Json.Decode
import Menu.Logout
import Menu.Msg as MenuMsg


type Msg
    = SelectMode Flashcard.Mode.Mode
    | Start
    | ReviewAnswer
    | Next
    | Prev
    | InputAnswer String
    | SubmitAnswer
    | RateQuality Int
    | WebSocketResp (Result Json.Decode.Error WebSocket.WebSocketMsg)
    | LogOut MenuMsg.Msg
    | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)
