module Flashcard.Msg exposing (..)

import Flashcard.Mode
import Http
import Menu.Logout
import Menu.Msg as MenuMsg

import Json.Decode
import WebSocket


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
