module Text.Translations exposing (..)

import Flags

import Dict exposing (Dict)

import Set exposing (Set)


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

type URL = URL String

type AddTextWordEndpoint = AddTextWordEndpoint URL
type MergeTextWordEndpoint = MergeTextWordEndpoint URL

type MergeState = Mergeable | Cancelable

type alias Flags = {
    add_as_text_word_endpoint_url: AddTextWordEndpoint
  , group_word_endpoint_url: MergeTextWordEndpoint
  , csrftoken : Flags.CSRFToken }

type alias Translation = {
   id: Int
 , endpoint: String
 , correct_for_context: Bool
 , text: String
 }

type alias Translations = List Translation

type alias Grammemes = Dict String String


expectedGrammemeKeys : Set String
expectedGrammemeKeys = Set.fromList [
   "pos"
 , "tense"
 , "aspect"
 , "form"
 , "mood"
 ]
