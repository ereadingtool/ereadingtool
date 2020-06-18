module Flashcard.Msg exposing (..)

import Flashcard.Mode
import Http
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
    | WebSocketResp String
    | LogOut MenuMsg.Msg
    | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)
