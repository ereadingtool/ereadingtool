module Quiz.Decode exposing (quizDecoder, quizCreateRespDecoder, decodeRespErrors, QuizRespError, QuizDeleteResp
  , quizUpdateRespDecoder, QuizCreateResp, QuizUpdateResp, quizListDecoder, quizLockRespDecoder
  , QuizLockResp, quizDeleteRespDecoder)

import Quiz.Model exposing (Quiz, QuizListItem)
import Text.Decode

import Array exposing (Array)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

import Dict exposing (Dict)
import Json.Decode.Extra exposing (date)


type alias QuizCreateResp = { id: Int, redirect: String }
type alias QuizUpdateResp = { id: Int, updated: Bool }
type alias QuizDeleteResp = { id: Int, redirect: String, deleted: Bool }
type alias QuizLockResp = { locked: Bool }

type alias QuizRespError = Dict String String

quizDecoder : Decode.Decoder Quiz
quizDecoder =
  decode Quiz
    |> required "id" (Decode.nullable (Decode.int))
    |> required "title" (Decode.string)
    |> required "introduction" (Decode.string)
    |> required "created_by" (Decode.nullable (Decode.string))
    |> required "last_modified_by" (Decode.nullable (Decode.string))
    |> required "tags" (Decode.nullable (Decode.list (Decode.string)))
    |> required "created_dt" (Decode.nullable date)
    |> required "modified_dt" (Decode.nullable date)
    |> required "texts" (Decode.map Array.fromList (Text.Decode.textsDecoder))
    |> required "write_locker" (Decode.nullable (Decode.string))

quizListItemDecoder : Decode.Decoder QuizListItem
quizListItemDecoder =
  decode QuizListItem
    |> required "id" Decode.int
    |> required "title" Decode.string
    |> required "created_by" (Decode.string)
    |> required "last_modified_by" (Decode.nullable (Decode.string))
    |> required "tags" (Decode.nullable (Decode.list (Decode.string)))
    |> required "created_dt" date
    |> required "modified_dt" date
    |> required "text_count" Decode.int
    |> required "write_locker" (Decode.nullable (Decode.string))


quizListDecoder : Decode.Decoder (List QuizListItem)
quizListDecoder =
  Decode.list quizListItemDecoder

quizCreateRespDecoder : Decode.Decoder (QuizCreateResp)
quizCreateRespDecoder =
  decode QuizCreateResp
    |> required "id" Decode.int
    |> required "redirect" Decode.string

quizUpdateRespDecoder : Decode.Decoder (QuizUpdateResp)
quizUpdateRespDecoder =
  decode QuizUpdateResp
    |> required "id" Decode.int
    |> required "updated" Decode.bool

quizDeleteRespDecoder : Decode.Decoder (QuizDeleteResp)
quizDeleteRespDecoder =
  decode QuizDeleteResp
    |> required "id" Decode.int
    |> required "redirect" Decode.string
    |> required "deleted" Decode.bool

quizLockRespDecoder : Decode.Decoder (QuizLockResp)
quizLockRespDecoder =
  decode QuizLockResp
    |> required "locked" Decode.bool

decodeRespErrors : String -> Result String QuizRespError
decodeRespErrors str = Decode.decodeString (Decode.field "errors" (Decode.dict Decode.string)) str
