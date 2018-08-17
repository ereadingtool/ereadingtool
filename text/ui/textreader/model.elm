module TextReader.Model exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)

import TextReader.Question exposing (TextQuestion, Question)

import TextReader exposing (TextItemAttributes, WebSocketAddress)

import Flags exposing (CSRFToken)

import Date exposing (Date)

import Profile

type Section = Section TextSection (TextItemAttributes {}) (Array TextQuestion)

type Progress = Init | ViewIntro | ViewSection Int | Complete

type alias Word = String

type CmdReq =
    StartReq
  | NextReq
  | AnswerReq Int
  | CurrentSectionReq
  | TextReq

type CmdResp =
    StartResp Bool
  | NextResp Bool
  | AnswerResp Bool
  | CurrentSectionResp Bool
  | TextResp Text

type alias TextSection = {
    order: Int
  , body : String
  , question_count : Int
  , questions : Array Question }

type alias Text = {
    id: Int
  , title: String
  , introduction: String
  , author: String
  , source: String
  , difficulty: String
  , conclusion: String
  , created_by: Maybe String
  , last_modified_by: Maybe String
  , tags: Maybe (List String)
  , created_dt: Maybe Date
  , modified_dt: Maybe Date
  , sections: Array TextSection }

emptyText : Text
emptyText = {
    id=0
  , title=""
  , introduction=""
  , author=""
  , source=""
  , difficulty=""
  , conclusion=""
  , created_by=Nothing
  , last_modified_by=Nothing
  , tags=Nothing
  , created_dt=Nothing
  , modified_dt=Nothing
  , sections=Array.fromList []
  }

type alias Flags = Flags.Flags { text_id : Int, text_reader_ws_addr: WebSocketAddress }

type alias Model = {
    text : Text
  , profile : Profile.Profile
  , progress: Progress
  , sections : Array Section
  , gloss : Dict String Bool
  , flags : Flags }
