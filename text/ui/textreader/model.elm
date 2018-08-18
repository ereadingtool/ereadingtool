module TextReader.Model exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)

import TextReader.Question exposing (TextQuestion, Question)

import TextReader exposing (TextItemAttributes, WebSocketAddress)

import Flags exposing (CSRFToken)

import Date exposing (Date)

import Profile

type Section = Section TextSection (Array TextQuestion)

type Progress = Init | ViewIntro | ViewSection Section | Complete

type alias Word = String

type CmdReq =
    StartReq
  | NextReq
  | AnswerReq Int
  | CurrentSectionReq
  | TextReq
  | CompleteReq

type CmdResp =
    StartResp Text
  | NextResp TextSection
  | CompleteResp TextScores
  | AnswerResp Bool

-- TODO (andrew): interesting stats go here
type alias TextScores = {

  }

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
  , modified_dt: Maybe Date }

emptyTextSection : TextSection
emptyTextSection = {
    order=0
  , body=""
  , question_count=0
  , questions=Array.fromList []
  }

newSection : TextSection -> Section
newSection text_section =
  Section text_section (Array.map TextReader.Question.gen_text_question text_section.questions)

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
  , modified_dt=Nothing }

type alias Flags = Flags.Flags { text_id : Int, text_reader_ws_addr: WebSocketAddress }

type alias Model = {
    text : Text
  , profile : Profile.Profile
  , progress: Progress
  , gloss : Dict String Bool
  , flags : Flags }
