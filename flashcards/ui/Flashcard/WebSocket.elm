port module Flashcard.WebSocket exposing (wsReceive, sendCommand, connect, disconnect)

import Json.Decode
import Json.Encode

import Flashcard.Msg exposing (Msg(..))
import Flashcard.Model exposing (CmdReq)
import Flashcard.Encode

import WebSocket

port receiveSocketMsg : (Json.Decode.Value -> msg) -> Sub msg
port sendSocketCommand : Json.Encode.Value -> Cmd msg

wsReceive = receiveSocketMsg <| WebSocket.receive WebSocketResp
wsSend = WebSocket.send sendSocketCommand


connect : String -> String -> String -> Cmd Msg
connect name address protocol =
    wsSend <| WebSocket.Connect {name = name, address = address, protocol = protocol}


disconnect : String -> Cmd Msg
disconnect name =
    wsSend <| WebSocket.Close {name = name}

sendCommand : String -> CmdReq -> Cmd Msg
sendCommand webSocketName cmdReq =
      wsSend
   <| WebSocket.Send {name = webSocketName, content = Flashcard.Encode.commandRequestToString cmdReq}