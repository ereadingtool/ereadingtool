module Text.Decode exposing (..)

import Text.Model exposing (Text, TextDifficulty, TextListItem)
import Text.Translations.Decode

import Text.Section.Decode

import Array exposing (Array)

import Util

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
    |> required "words" Text.Translations.Decode.wordsDecoder

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
    |> required "last_read_dt" (Decode.nullable date)
    |> required "text_section_count" Decode.int
    |> required "text_sections_complete" (Decode.nullable Decode.int)
    |> required "questions_correct" (Decode.nullable Util.intTupleDecoder)
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

textDifficultiesDecoder : Decode.Decoder (List TextDifficulty)
textDifficultiesDecoder =
  Decode.list textDifficultyDecoder

textDifficultyDecoder : Decode.Decoder TextDifficulty
textDifficultyDecoder =
  Util.stringTupleDecoder

decodeRespErrors : String -> Result String TextsRespError
decodeRespErrors str =
  Decode.decodeString (Decode.field "errors" (Decode.dict Decode.string)) str

textProgressDecoder : Decode.Decoder (TextProgressUpdateResp)
textProgressDecoder =
    decode TextProgressUpdateResp
    |> required "updated" Decode.bool