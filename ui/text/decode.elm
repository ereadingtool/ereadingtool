module Text.Decode exposing (..)

import Text.Model exposing (Text, TextDifficulty, TextListItem, WordValues, Words)
import Text.Translations exposing (Word)

import Text.Section.Decode

import Array exposing (Array)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

import Dict exposing (Dict)
import Json.Decode.Extra exposing (date)

type alias TextCreateResp = { id: Int, redirect: String }
type alias TextUpdateResp = { id: Int, updated: Bool }
type alias TextDeleteResp = { id: Int, redirect: String, deleted: Bool }
type alias TextLockResp = { locked: Bool }
type alias TextProgressUpdateResp = { updated: Bool }

type alias TextsRespError = Dict String String

type alias TextWordTranslationDeleteResp = { id: Int, translation: Text.Model.TextWordTranslation, deleted: Bool }

grammemesDecoder : Decode.Decoder Text.Model.Grammemes
grammemesDecoder =
  Decode.dict (Decode.nullable Decode.string)

wordValuesDecoder : Decode.Decoder WordValues
wordValuesDecoder =
  decode WordValues
    |> required "grammemes" grammemesDecoder
    |> required "translations" (Decode.nullable (Decode.list Decode.string))

wordsDecoder : Decode.Decoder Words
wordsDecoder =
  Decode.dict wordValuesDecoder

textDecoder : Decode.Decoder Text
textDecoder =
  decode Text
    |> required "id" (Decode.nullable Decode.int)
    |> required "title" Decode.string
    |> required "introduction" Decode.string
    |> required "author" Decode.string
    |> required "source" Decode.string
    |> required "difficulty" Decode.string
    |> required "conclusion" (Decode.nullable Decode.string)
    |> required "created_by" (Decode.nullable Decode.string)
    |> required "last_modified_by" (Decode.nullable Decode.string)
    |> required "tags" (Decode.nullable (Decode.list Decode.string))
    |> required "created_dt" (Decode.nullable date)
    |> required "modified_dt" (Decode.nullable date)
    |> required "text_sections" (Decode.map Array.fromList (Text.Section.Decode.textSectionsDecoder))
    |> required "write_locker" (Decode.nullable Decode.string)
    |> required "words" wordsDecoder

textListItemDecoder : Decode.Decoder TextListItem
textListItemDecoder =
  decode TextListItem
    |> required "id" Decode.int
    |> required "title" Decode.string
    |> required "author" Decode.string
    |> required "difficulty" Decode.string
    |> required "created_by" Decode.string
    |> required "last_modified_by" (Decode.nullable Decode.string)
    |> required "tags" (Decode.nullable (Decode.list Decode.string))
    |> required "created_dt" date
    |> required "modified_dt" date
    |> required "text_section_count" Decode.int
    |> required "text_sections_complete" (Decode.nullable Decode.int)
    |> required "uri" Decode.string
    |> required "write_locker" (Decode.nullable Decode.string)


textListDecoder : Decode.Decoder (List TextListItem)
textListDecoder =
  Decode.list textListItemDecoder

textCreateRespDecoder : Decode.Decoder (TextCreateResp)
textCreateRespDecoder =
  decode TextCreateResp
    |> required "id" Decode.int
    |> required "redirect" Decode.string

textUpdateRespDecoder : Decode.Decoder (TextUpdateResp)
textUpdateRespDecoder =
  decode TextUpdateResp
    |> required "id" Decode.int
    |> required "updated" Decode.bool

textDeleteRespDecoder : Decode.Decoder (TextDeleteResp)
textDeleteRespDecoder =
  decode TextDeleteResp
    |> required "id" Decode.int
    |> required "redirect" Decode.string
    |> required "deleted" Decode.bool

textLockRespDecoder : Decode.Decoder (TextLockResp)
textLockRespDecoder =
  decode TextLockResp
    |> required "locked" Decode.bool

textDifficultyDecoder : Decode.Decoder (List TextDifficulty)
textDifficultyDecoder =
  Decode.keyValuePairs Decode.string

textTranslationUpdateRespDecoder : Decode.Decoder (Word, Text.Model.TextWordTranslation)
textTranslationUpdateRespDecoder =
  Decode.map2 (,) (Decode.field "word" Decode.string) (Decode.field "translation" textWordTranslationsDecoder)

textTranslationAddRespDecoder : Decode.Decoder (Word, Text.Model.TextWordTranslation)
textTranslationAddRespDecoder =
  Decode.map2 (,) (Decode.field "word" Decode.string) (Decode.field "translation" textWordTranslationsDecoder)

textTranslationRemoveRespDecoder : Decode.Decoder TextWordTranslationDeleteResp
textTranslationRemoveRespDecoder =
  decode TextWordTranslationDeleteResp
    |> required "id" Decode.int
    |> required "translation" textWordTranslationsDecoder
    |> required "deleted" Decode.bool

textTranslationsDecoder : Decode.Decoder (Dict String (Dict Word Text.Model.TextWord))
textTranslationsDecoder =
  Decode.dict (Decode.dict textWordDecoder)

textWordTranslationsDecoder : Decode.Decoder Text.Model.TextWordTranslation
textWordTranslationsDecoder =
  decode Text.Model.TextWordTranslation
    |> required "id" Decode.int
    |> required "correct_for_context" Decode.bool
    |> required "text" Decode.string

textWordDecoder : Decode.Decoder Text.Model.TextWord
textWordDecoder =
  decode Text.Model.TextWord
    |> required "id" Decode.int
    |> required "instance" Decode.int
    |> required "word" Decode.string
    |> required "grammemes" grammemesDecoder
    |> required "translations" (Decode.nullable (Decode.list textWordTranslationsDecoder))

decodeRespErrors : String -> Result String TextsRespError
decodeRespErrors str =
  Decode.decodeString (Decode.field "errors" (Decode.dict Decode.string)) str

textProgressDecoder : Decode.Decoder (TextProgressUpdateResp)
textProgressDecoder =
    decode TextProgressUpdateResp
    |> required "updated" Decode.bool