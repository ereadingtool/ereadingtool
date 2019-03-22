module Flashcard.Model exposing (..)

import User.Profile

import Profile.Flags as Flags

import Flashcard.Mode


type alias Exception = { code: String, error_msg: String }

type alias Example = String
type alias Phrase = String
type alias WebSocketAddress = String

type alias Flags = Flags.Flags { profile_id : Int, flashcard_ws_addr: WebSocketAddress }

type alias InitRespRec = {
  flashcards: List String
 }

type SessionState =
    Loading
  | Init InitRespRec
  | ViewModeChoices (List Flashcard.Mode.ModeChoiceDesc)
  | ReviewCard Flashcard
  | ReviewCardAndAnswer Flashcard


type Flashcard = Flashcard Phrase Example


newFlashcard : Phrase -> Example -> Flashcard
newFlashcard phrase example =
  Flashcard phrase example

example : Flashcard -> Example
example (Flashcard _ example) =
  example

phrase : Flashcard -> Phrase
phrase (Flashcard phrase _) =
  phrase

type alias Model = {
    profile : User.Profile.Profile
  , session_state: SessionState
  , exception : Maybe Exception
  , flags : Flags }

type CmdReq =
    ChooseModeReq Flashcard.Mode.ModeChoice
  | StartReq
  | NextReq
  | AnswerReq String
  | RateAnswerReq Int

type CmdResp =
    InitResp InitRespRec
  | ChooseModeChoiceResp (List Flashcard.Mode.ModeChoiceDesc)
  | ReviewCardResp Flashcard
  | ReviewCardAndAnswerResp Flashcard
  | ExceptionResp Exception