module TextReader.Model exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)

import TextReader.Question exposing (TextQuestion)

import TextReader exposing (TextItemAttributes, WebSocketAddress)

import Flags exposing (CSRFToken)
import Text.Section.Model exposing (TextSection, emptyTextSection)
import Text.Model as Texts exposing (Text)

import Profile

type Section = Section TextSection (TextItemAttributes {}) (Array TextQuestion)

type Progress = Init | ViewIntro | ViewSection Int | Complete

type alias Word = String

type CmdReq = StartReq | NextReq | AnswerReq Int | CurrentSectionReq
type CmdResp = StartResp Bool | NextResp Bool | AnswerResp Bool | CurrentSectionResp Bool

type Command = Command CmdReq CmdResp


type alias Flags = Flags.Flags { text_id : Int, text_reader_ws_addr: WebSocketAddress }

type alias Model = {
    text : Text
  , profile : Profile.Profile
  , progress: Progress
  , sections : Array Section
  , gloss : Dict String Bool
  , flags : Flags }
