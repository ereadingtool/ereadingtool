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


grammemeValue : Grammemes -> String -> Maybe String
grammemeValue grammemes name =
  case name of
    "pos" ->
      grammemes.pos

    "tense" ->
      grammemes.tense

    "aspect" ->
      grammemes.aspect

    "form" ->
      grammemes.form

    "mood" ->
      grammemes.mood

    _ ->
      Nothing

grammemeKeys : Set String
grammemeKeys = Set.fromList [
   "pos"
 , "tense"
 , "aspect"
 , "form"
 , "mood"
 ]

maybeToBool : Maybe a -> Bool
maybeToBool maybe =
  case maybe of
    Just _ ->
      True

    Nothing ->
      False

definedGrammemes : Grammemes -> List (String, Bool)
definedGrammemes grammemes =
  [ ("pos", maybeToBool grammemes.pos)
  , ("tense", maybeToBool grammemes.tense)
  , ("aspect", maybeToBool grammemes.aspect)
  , ("form", maybeToBool grammemes.form)
  , ("mood", maybeToBool grammemes.mood)
  ]