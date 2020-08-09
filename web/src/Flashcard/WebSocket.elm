port module Flashcard.WebSocket exposing (connect, disconnect, sendCommand, wsReceive)

import Flashcard.Encode
import Flashcard.Model exposing (CmdReq)
import Flashcard.Msg exposing (Msg(..))
import Json.Decode
import Json.Encode
import WebSocket


port receiveSocketMsg : (Json.Decode.Value -> msg) -> Sub msg


port sendSocketCommand : Json.Encode.Value -> Cmd msg


wsReceive =
    receiveSocketMsg <| WebSocket.receive WebSocketResp


wsSend =
    WebSocket.send sendSocketCommand


webSocketName : String
webSocketName =
    "flashcard"


connect : String -> String -> Cmd Msg
connect address protocol =
    wsSend <| WebSocket.Connect { name = webSocketName, address = address, protocol = protocol }


disconnect : String -> Cmd Msg
disconnect name =
    wsSend <| WebSocket.Close { name = name }


sendCommand : CmdReq -> Cmd Msg
sendCommand cmdReq =
    wsSend <|
        WebSocket.Send { name = webSocketName, content = Flashcard.Encode.commandRequestToString cmdReq }
