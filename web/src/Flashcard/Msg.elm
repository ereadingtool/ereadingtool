module Flashcard.Msg exposing (Msg(..))

import Api.WebSocket as WebSocket
import Flashcard.Mode
import Http
import Json.Decode


type Msg
    = SelectMode Flashcard.Mode.Mode
    | Start
    | ReviewAnswer
    | Next
    | Prev
    | InputAnswer String
    | SubmitAnswer
    | RateQuality Int
    | WebSocketResp (Result Json.Decode.Error WebSocket.WebSocketMsg)
    | Logout
