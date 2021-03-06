module Flashcard.Msg exposing (..)

import Http

import Menu.Msg as MenuMsg
import Menu.Logout

import Flashcard.Mode

type Msg =
    SelectMode Flashcard.Mode.Mode
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