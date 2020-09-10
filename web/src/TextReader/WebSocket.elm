port module TextReader.WebSocket exposing (..)

import Api.WebSocket as WebSocket exposing (WebSocketCmd)
import Json.Decode
import Json.Encode
import TextReader.Encode
import TextReader.Model


port receiveSocketMsg : (Json.Decode.Value -> msg) -> Sub msg


port sendSocketCommand : Json.Encode.Value -> Cmd msg



-- wsReceive = receiveSocketMsg <| WebSocket.receive WebSocketResp


wsSend =
    WebSocket.send sendSocketCommand


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



-- listen : Sub msg
-- -- listen : Sub Msg
-- listen =
--     wsReceive


connect : WebSocketAddress -> String -> Cmd msg



-- connect : WebSocketAddress -> String -> Cmd Msg


connect address protocol =
    wsSend <| WebSocket.Connect { name = webSocketName, address = toString address, protocol = protocol }


disconnect : Cmd msg



-- disconnect : Cmd Msg


disconnect =
    wsSend <| WebSocket.Close { name = webSocketName }


sendCommand : TextReader.Model.CmdReq -> Cmd msg



-- sendCommand : TextReader.Model.CmdReq -> Cmd Msg


sendCommand cmdReq =
    wsSend <|
        -- WebSocket.Send { name = webSocketName, content = TextReader.Encode.commandRequestToString cmdReq }
        WebSocket.Send { name = webSocketName, content = TextReader.Encode.sendCommand cmdReq }
