module TextReader.Encode exposing (..)

import TextReader.Model exposing (..)
import Json.Encode



jsonToString : (Json.Encode.Value -> String)
jsonToString = (Json.Encode.encode 0)


send_command : CmdReq -> Json.Encode.Value
send_command cmd_req =
  case cmd_req of
    StartReq ->
      Json.Encode.object [
        ("command", Json.Encode.string "start")
      ]

    TextReq ->
      Json.Encode.object [
        ("command", Json.Encode.string "text")
      ]

    NextReq ->
      Json.Encode.object [
        ("command", Json.Encode.string  "next")
      ]

    AnswerReq answer_id ->
      Json.Encode.object [
        ("command", Json.Encode.string "answer")
      , ("answer_id", Json.Encode.int answer_id)
      ]

    CurrentSectionReq ->
      Json.Encode.object [
        ("command", Json.Encode.string "current_section")
      ]

