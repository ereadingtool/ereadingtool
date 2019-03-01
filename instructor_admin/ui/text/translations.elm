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

type MergeState = Mergeable | Cancelable

type alias Flags = { group_word_endpoint_url: String, csrftoken : Flags.CSRFToken }

type alias Translation = {
   id: Int
 , endpoint: String
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

grammeme_keys : Set String
grammeme_keys = Set.fromList [
   "pos"
 , "tense"
 , "aspect"
 , "form"
 , "mood"
 ]

maybe_to_bool : Maybe a -> Bool
maybe_to_bool maybe =
  case maybe of
    Just _ ->
      True

    Nothing ->
      False

defined_grammemes : Grammemes -> List (String, Bool)
defined_grammemes grammemes =
  [ ("pos", maybe_to_bool grammemes.pos)
  , ("tense", maybe_to_bool grammemes.tense)
  , ("aspect", maybe_to_bool grammemes.aspect)
  , ("form", maybe_to_bool grammemes.form)
  , ("mood", maybe_to_bool grammemes.mood)
  ]