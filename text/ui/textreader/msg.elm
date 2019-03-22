module TextReader.Msg exposing (..)

import Http

import TextReader.Model exposing (TextReaderWord)

import TextReader.Section.Model exposing (Section)
import TextReader.Question.Model exposing (TextQuestion)
import TextReader.Answer.Model exposing (TextAnswer)

import Menu.Msg as MenuMsg
import Menu.Logout


type Msg =
    Select TextAnswer
  | ViewFeedback Section TextQuestion TextAnswer Bool
  | PrevSection
  | NextSection
  | StartOver
  | Gloss TextReaderWord
  | UnGloss TextReaderWord
  | AddToFlashcards TextReaderWord
  | RemoveFromFlashcards TextReaderWord
  | WebSocketResp String
  | LogOut MenuMsg.Msg
  | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)