module Flashcard.Model exposing (..)

import User.Profile

import Profile.Flags as Flags


type alias Exception = { code: String, error_msg: String }

type alias WebSocketAddress = String

type alias Flags = Flags.Flags { profile_id : Int, flashcard_ws_addr: WebSocketAddress }


type Session = Init | ReviewedCard


type alias Model = {
    profile : User.Profile.Profile
  , session: Session
  , exception : Maybe Exception
  , flags : Flags }


type CmdReq =
    NextReq
  | PrevReq
  | AnswerReq String
  | RateAnswerReq Int

type CmdResp =
    InitResp String
  | ExceptionResp Exception