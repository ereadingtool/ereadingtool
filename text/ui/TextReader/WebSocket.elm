port module TextReader.WebSocket exposing (..)

import TextReader.Msg exposing (Msg(..))
import TextReader.Model
import TextReader.Encode

import Json.Decode
import Json.Encode

import WebSocket

port receiveSocketMsg : (Json.Decode.Value -> msg) -> Sub msg
port sendSocketCommand : Json.Encode.Value -> Cmd msg

wsReceive = receiveSocketMsg <| WebSocket.receive WebSocketResp
wsSend = WebSocket.send sendSocketCommand


type WebSocketAddress
    = WebSocketAddress String


webSocketName : String
webSocketName =
    "textreader"

toString : WebSocketAddress -> String
toString (WebSocketAddress addr) =
    addr

toAddress : String -> WebSocketAddress
toAddress addr =
    WebSocketAddress addr

listen : Sub Msg
listen =
    wsReceive

connect : WebSocketAddress -> String -> Cmd Msg
connect address protocol =
    wsSend <| WebSocket.Connect {name = webSocketName, address = toString address, protocol = protocol}

disconnect : Cmd Msg
disconnect =
    wsSend <| WebSocket.Close {name = webSocketName}

sendCommand : TextReader.Model.CmdReq -> Cmd Msg
sendCommand cmdReq =
      wsSend
   <| WebSocket.Send {name = webSocketName, content = TextReader.Encode.commandRequestToString cmdReq}