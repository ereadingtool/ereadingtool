module Flashcard.Msg exposing (..)

import Http

import Menu.Msg as MenuMsg
import Menu.Logout


type Msg =
    SelectMode String
  | WebSocketResp String
  | LogOut MenuMsg.Msg
  | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)