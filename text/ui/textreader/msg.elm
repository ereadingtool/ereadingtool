module TextReader.Msg exposing (..)

import TextReader.Model exposing (..)

import TextReader.Question exposing (TextQuestion)
import TextReader.Answer exposing (TextAnswer)


-- UPDATE
type Msg =
    Select Section TextQuestion TextAnswer Bool
  | ViewFeedback Section TextQuestion TextAnswer Bool
  | PrevSection
  | NextSection
  | Started Bool
  | StartOver
  | Gloss Word
  | UnGloss Word
  | WebSocketResp String