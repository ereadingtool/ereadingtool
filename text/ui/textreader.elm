module TextReader exposing (..)


type alias Selected = Bool
type alias AnsweredCorrectly = Bool
type alias FeedbackViewable = Bool
type alias WebSocketAddress = String

type alias TextItemAttributes a = { a | index : Int }
