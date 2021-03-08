module TextReader.Msg exposing (..)

import Http
import Menu.Logout
import Menu.Msg as MenuMsg
import TextReader.Answer.Model exposing (TextAnswer)
import TextReader.Model exposing (TextReaderWord)
import TextReader.Question.Model exposing (TextQuestion)
import TextReader.Section.Model exposing (Section)

import Json.Decode
import WebSocket

type Msg
    = Select TextAnswer
    | ViewFeedback Section TextQuestion TextAnswer Bool
    | PrevSection
    | NextSection
    | StartOver
    | Gloss TextReaderWord
    | UnGloss TextReaderWord
    | ToggleGloss TextReaderWord
    | AddToFlashcards TextReaderWord
    | RemoveFromFlashcards TextReaderWord
    | WebSocketResp (Result Json.Decode.Error WebSocket.WebSocketMsg)
    | LogOut MenuMsg.Msg
    | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)
