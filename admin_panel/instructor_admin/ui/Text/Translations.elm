module Text.Translations exposing (..)

import Flags

import Dict exposing (Dict)

import Set exposing (Set)


type SectionNumber = SectionNumber Int

sectionNumberToInt : SectionNumber -> Int
sectionNumberToInt (SectionNumber section_number) =
  section_number

type TextWordId = TextWordId Int

textWordIdToInt : TextWordId -> Int
textWordIdToInt (TextWordId id) =
  id

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
type GroupWordEndpoint = GroupWordEndpoint URL
type TextTranslationMatchEndpoint = TextTranslationMatchEndpoint URL

type MergeState = Mergeable | Cancelable

type alias Flags = {
    add_as_text_word_endpoint_url: String
  , merge_textword_endpoint_url: String
  , text_translation_match_endpoint: String
  , csrftoken : Flags.CSRFToken }


type alias Translation = {
   id: Int
 , endpoint: String
 , correct_for_context: Bool
 , text: String
 }

type alias Translations = List Translation

type alias Grammemes = Dict String String


urlToString : URL -> String
urlToString (URL url) =
  url

mergeTextWordEndpointURL : MergeTextWordEndpoint -> URL
mergeTextWordEndpointURL (MergeTextWordEndpoint url) =
  url

addTextWordEndpointURL : AddTextWordEndpoint -> URL
addTextWordEndpointURL (AddTextWordEndpoint url) =
  url

textTransMatchEndpointURL : TextTranslationMatchEndpoint -> URL
textTransMatchEndpointURL (TextTranslationMatchEndpoint url) =
  url

textTransMatchEndpointToString : TextTranslationMatchEndpoint -> String
textTransMatchEndpointToString endpoint =
  urlToString (textTransMatchEndpointURL endpoint)

addTextWordEndpointToString : AddTextWordEndpoint -> String
addTextWordEndpointToString endpoint =
  urlToString (addTextWordEndpointURL endpoint)

mergeTextWordEndpointToString : MergeTextWordEndpoint -> String
mergeTextWordEndpointToString endpoint =
  urlToString (mergeTextWordEndpointURL endpoint)

expectedGrammemeKeys : Set String
expectedGrammemeKeys = Set.fromList [
   "pos"
 , "tense"
 , "aspect"
 , "form"
 , "mood"
 ]
