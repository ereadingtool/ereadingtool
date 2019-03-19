module Flashcard.Encode exposing (..)

import Json.Encode

import Flashcard.Model exposing (..)


jsonToString : (Json.Encode.Value -> String)
jsonToString = (Json.Encode.encode 0)


send_command : CmdReq -> Json.Encode.Value
send_command cmd_req =
  case cmd_req of
    NextReq ->
      Json.Encode.object [
        ("command", Json.Encode.string  "next")
      ]

    PrevReq ->
      Json.Encode.object [
        ("command", Json.Encode.string  "prev")
      ]

    _ ->
      Json.Encode.object []
