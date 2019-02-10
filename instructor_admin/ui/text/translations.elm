module Text.Translations exposing (..)

import Json.Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

import Flags

import Dict exposing (Dict)


type alias Id = String
type alias Instance = Int
type alias Phrase = String
type alias Word = String
type alias Token = String
type alias Meaning = String

type alias WordValues = {
    grammemes: Grammemes
  , translations: Maybe (List String) }

type alias TextGroupDetails = {
    id: Int
  , instance: Int
  , pos: Int
  , length: Int
  }

type alias Words = Dict Word WordValues

type MergeState = Mergeable | Cancelable

type alias Flags = { group_word_endpoint_url: String, csrftoken : Flags.CSRFToken }

type alias Translation = {
   id: Int
 , correct_for_context: Bool
 , text: String
 }

type alias Translations = List Translation

type alias Grammemes = {
    pos: Maybe String
  , tense: Maybe String
  , aspect: Maybe String
  , form: Maybe String
  , mood: Maybe String }

