module TextReader.Msg exposing (..)

import TextReader.Model exposing (..)

import TextReader.Section.Model exposing (Section)
import TextReader.Question.Model exposing (TextQuestion)
import TextReader.Answer.Model exposing (TextAnswer)


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