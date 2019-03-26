module Flashcard.Model exposing (..)

import User.Profile

import Profile.Flags as Flags

import Flashcard.Mode exposing (Mode)


type alias Exception = { code: String, error_msg: String }

type alias Example = String
type alias Phrase = String
type alias WebSocketAddress = String

type alias TranslatedPhrase = String

type alias Flags = Flags.Flags { profile_id : Int, flashcard_ws_addr: WebSocketAddress }

type alias InitRespRec = {
  flashcards: List String
 }

type SessionState =
    Loading
  | Init InitRespRec
  | ViewModeChoices (List Flashcard.Mode.ModeChoiceDesc)
  | ReviewCard Flashcard
  | ReviewedCard Flashcard
  | ReviewCardAndAnswer Flashcard
  | FinishedReview


type Flashcard = Flashcard Phrase Example (Maybe TranslatedPhrase)


disconnect : Model -> Model
disconnect model =
  { model | connect = False }

setMode : Model -> Maybe Mode -> Model
setMode model mode =
  { model | mode = mode }

setSessionState : Model -> SessionState -> Model
setSessionState model session_state =
  { model | session_state = session_state }

setException : Model -> Maybe Exception -> Model
setException model exception =
  { model | exception = exception }

hasException : Model -> Bool
hasException model =
  case model.exception of
    Just _ -> True

    _ -> False

newFlashcard : Phrase -> Example -> Maybe TranslatedPhrase -> Flashcard
newFlashcard phrase example translation =
  Flashcard phrase example translation

example : Flashcard -> Example
example (Flashcard _ example _) =
  "\"" ++ example ++ "\""

phrase : Flashcard -> Phrase
phrase (Flashcard phrase _ _) =
  phrase

translation : Flashcard -> Maybe TranslatedPhrase
translation (Flashcard _ _ translation) =
  translation

hasTranslation : Flashcard -> Bool
hasTranslation flashcard =
  case translation flashcard of
    Just _ ->
      True

    _ ->
      False

translationOrPhrase : Flashcard -> String
translationOrPhrase flashcard =
  case (translation flashcard) of
    Just tr ->
      tr ++ " - " ++ (phrase flashcard)

    Nothing ->
      (phrase flashcard)

type alias Model = {
    profile : User.Profile.Profile
  , mode: Maybe Mode
  , session_state: SessionState
  , exception : Maybe Exception
  , connect : Bool
  , flags : Flags }

type CmdReq =
    ChooseModeReq Mode
  | StartReq
  | NextReq
  | PrevReq
  | ReviewAnswerReq
  | AnswerReq String
  | RateAnswerReq Int

type CmdResp =
    InitResp InitRespRec
  | ChooseModeChoiceResp (List Flashcard.Mode.ModeChoiceDesc)
  | ReviewCardResp Flashcard
  | ReviewCardAndAnswerResp Flashcard
  | ReviewedCardResp Flashcard
  | ExceptionResp Exception
  | FinishedReviewResp