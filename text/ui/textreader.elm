module TextReader exposing (..)

type Selected = Selected Bool
type AnsweredCorrectly = AnsweredCorrectly Bool
type FeedbackViewable = FeedbackViewable Bool
type WebSocketAddress = WebSocketAddress String


webSocketAddrToString : WebSocketAddress -> String
webSocketAddrToString (WebSocketAddress addr) = addr

