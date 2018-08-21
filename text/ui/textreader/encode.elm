module TextReader.Encode exposing (..)

import TextReader.Model exposing (..)
import Json.Encode



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

    AnswerReq answer_id ->
      Json.Encode.object [
        ("command", Json.Encode.string "answer")
      , ("answer_id", Json.Encode.int answer_id)
      ]