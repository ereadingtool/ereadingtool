module Flashcard.Encode exposing (..)

import Json.Encode

import Flashcard.Model exposing (..)

import Flashcard.Mode


jsonToString : (Json.Encode.Value -> String)
jsonToString = (Json.Encode.encode 0)


send_command : CmdReq -> Json.Encode.Value
send_command cmd_req =
  case cmd_req of
    ChooseModeReq mode ->
      Json.Encode.object [
        ("command", Json.Encode.string "choose_mode")
      , ("mode", Json.Encode.string (Flashcard.Mode.modeId mode))
      ]

    NextReq ->
      Json.Encode.object [
        ("command", Json.Encode.string  "next")
      ]

    StartReq ->
      Json.Encode.object [
        ("command", Json.Encode.string  "start")
      ]

    ReviewAnswerReq ->
      Json.Encode.object [
        ("command", Json.Encode.string "review_answer")
      ]

    _ ->
      Json.Encode.object []
