module TextReader.Model exposing (..)

import Dict exposing (Dict)

import TextReader.Text.Model exposing (Text)
import TextReader.Section.Model exposing (Section)
import TextReader.Answer.Model exposing (TextAnswer, Answer, AnswerCorrect)

import TextReader exposing (TextItemAttributes, WebSocketAddress)

import Flags exposing (CSRFToken)

import Profile


type Progress = Init | ViewIntro | ViewSection Section | Complete TextScores

type alias Exception = { code: String, error_msg: String }

type alias Gloss = Dict String Bool

type CmdReq =
    NextReq
  | PrevReq
  | AnswerReq TextAnswer

type CmdResp =
    StartResp Text
  | InProgressResp Section
  | CompleteResp TextScores
  | ExceptionResp Exception

type alias TextScores = {
    num_of_sections: Int
  , complete_sections: Int
  , section_scores: Int
  , possible_section_scores: Int }


type alias Flags = Flags.Flags { text_id : Int, text_reader_ws_addr: WebSocketAddress }

type alias Model = {
    text : Text
  , profile : Profile.Profile
  , progress: Progress
  , gloss : Gloss
  , exception : Maybe Exception
  , flags : Flags }
