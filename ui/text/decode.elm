module Text.Decode exposing (textDecoder, textCreateRespDecoder, decodeRespErrors, TextRespError, TextDeleteResp
  , textUpdateRespDecoder, TextCreateResp, TextUpdateResp, textListDecoder, textLockRespDecoder
  , TextLockResp, textDeleteRespDecoder)

import Text.Model exposing (Text, TextListItem)
import Text.Decode

import Array exposing (Array)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

import Dict exposing (Dict)
import Json.Decode.Extra exposing (date)


type alias TextCreateResp = { id: Int, redirect: String }
type alias TextUpdateResp = { id: Int, updated: Bool }
type alias TextDeleteResp = { id: Int, redirect: String, deleted: Bool }
type alias TextLockResp = { locked: Bool }

type alias TextRespError = Dict String String

textDecoder : Decode.Decoder Text
textDecoder =
  decode Text
    |> required "id" (Decode.nullable (Decode.int))
    |> required "title" (Decode.string)
    |> required "introduction" (Decode.string)
    |> required "created_by" (Decode.nullable (Decode.string))
    |> required "last_modified_by" (Decode.nullable (Decode.string))
    |> required "tags" (Decode.nullable (Decode.list (Decode.string)))
    |> required "created_dt" (Decode.nullable date)
    |> required "modified_dt" (Decode.nullable date)
    |> required "sections" (Decode.map Array.fromList (Text.Section.Decode.textSectionDecoder))
    |> required "write_locker" (Decode.nullable (Decode.string))

textListItemDecoder : Decode.Decoder TextListItem
textListItemDecoder =
  decode TextListItem
    |> required "id" Decode.int
    |> required "title" Decode.string
    |> required "created_by" (Decode.string)
    |> required "last_modified_by" (Decode.nullable (Decode.string))
    |> required "tags" (Decode.nullable (Decode.list (Decode.string)))
    |> required "created_dt" date
    |> required "modified_dt" date
    |> required "text_count" Decode.int
    |> required "write_locker" (Decode.nullable (Decode.string))


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

decodeRespErrors : String -> Result String TextRespError
decodeRespErrors str = Decode.decodeString (Decode.field "errors" (Decode.dict Decode.string)) str
