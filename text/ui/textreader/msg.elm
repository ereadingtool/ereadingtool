module TextReader.Msg exposing (..)

import Http

import Text.Definitions exposing (Word)

import TextReader.Section.Model exposing (Section)
import TextReader.Question.Model exposing (TextQuestion)
import TextReader.Answer.Model exposing (TextAnswer)

import Menu.Msg as MenuMsg
import Menu.Logout


-- UPDATE
type Msg =
    Select TextAnswer
  | ViewFeedback Section TextQuestion TextAnswer Bool
  | PrevSection
  | NextSection
  | StartOver
  | Gloss Word
  | UnGloss Word
  | WebSocketResp String
  | LogOut MenuMsg.Msg
  | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)