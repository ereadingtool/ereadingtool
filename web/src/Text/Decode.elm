module Text.Decode exposing
    ( TextCreateResp
    , TextDeleteResp
    , TextLockResp
    , TextUpdateResp
    , decodeRespErrors
    , textCreateRespDecoder
    , textDecoder
    , textDeleteRespDecoder
    , textDifficultiesDecoder
    , textListDecoder
    , textLockRespDecoder
    , textUpdateRespDecoder
    )

import Array
import DateTime
import Dict exposing (Dict)
import Json.Decode
import Json.Decode.Extra exposing (posix)
import Json.Decode.Pipeline exposing (required)
import Text.Model exposing (Text, TextDifficulty, TextListItem)
import Text.Section.Decode
import Text.Translations.Decode
import Utils


type alias TextCreateResp =
    { id : Int
    , redirect : String
    }


type alias TextUpdateResp =
    { id : Int
    , updated : Bool
    }


type alias TextDeleteResp =
    { id : Int
    , redirect : String
    , deleted : Bool
    }


type alias TextLockResp =
    { locked : Bool }


type alias TextProgressUpdateResp =
    { updated : Bool }


type alias TextsRespError =
    Dict String String


textDecoder : Json.Decode.Decoder Text
textDecoder =
    Json.Decode.succeed Text
        |> required "id" (Json.Decode.nullable Json.Decode.int)
        |> required "title" Json.Decode.string
        |> required "introduction" Json.Decode.string
        |> required "author" Json.Decode.string
        |> required "source" Json.Decode.string
        |> required "difficulty" Json.Decode.string
        |> required "conclusion" (Json.Decode.nullable Json.Decode.string)
        |> required "created_by" (Json.Decode.nullable Json.Decode.string)
        |> required "last_modified_by" (Json.Decode.nullable Json.Decode.string)
        |> required "tags" (Json.Decode.nullable (Json.Decode.list Json.Decode.string))
        |> required "created_dt" (Json.Decode.nullable (Json.Decode.map DateTime.fromPosix posix))
        |> required "modified_dt" (Json.Decode.nullable (Json.Decode.map DateTime.fromPosix posix))
        |> required "text_sections" (Json.Decode.map Array.fromList Text.Section.Decode.textSectionsDecoder)
        |> required "write_locker" (Json.Decode.nullable Json.Decode.string)
        |> required "words" Text.Translations.Decode.wordsDecoder


textListItemDecoder : Json.Decode.Decoder TextListItem
textListItemDecoder =
    Json.Decode.succeed TextListItem
        |> required "id" Json.Decode.int
        |> required "title" Json.Decode.string
        |> required "author" Json.Decode.string
        |> required "difficulty" Json.Decode.string
        |> required "created_by" Json.Decode.string
        |> required "last_modified_by" (Json.Decode.nullable Json.Decode.string)
        |> required "tags" (Json.Decode.nullable (Json.Decode.list Json.Decode.string))
        |> required "created_dt" (Json.Decode.map DateTime.fromPosix posix)
        |> required "modified_dt" (Json.Decode.map DateTime.fromPosix posix)
        |> required "last_read_dt" (Json.Decode.nullable (Json.Decode.map DateTime.fromPosix posix))
        |> required "text_section_count" Json.Decode.int
        |> required "text_sections_complete" (Json.Decode.nullable Json.Decode.int)
        |> required "questions_correct" (Json.Decode.nullable Utils.intTupleDecoder)
        |> required "uri" Json.Decode.string
        |> required "write_locker" (Json.Decode.nullable Json.Decode.string)


textListDecoder : Json.Decode.Decoder (List TextListItem)
textListDecoder =
    Json.Decode.list textListItemDecoder


textCreateRespDecoder : Json.Decode.Decoder TextCreateResp
textCreateRespDecoder =
    Json.Decode.succeed TextCreateResp
        |> required "id" Json.Decode.int
        |> required "redirect" Json.Decode.string


textUpdateRespDecoder : Json.Decode.Decoder TextUpdateResp
textUpdateRespDecoder =
    Json.Decode.succeed TextUpdateResp
        |> required "id" Json.Decode.int
        |> required "updated" Json.Decode.bool


textDeleteRespDecoder : Json.Decode.Decoder TextDeleteResp
textDeleteRespDecoder =
    Json.Decode.succeed TextDeleteResp
        |> required "id" Json.Decode.int
        |> required "redirect" Json.Decode.string
        |> required "deleted" Json.Decode.bool


textLockRespDecoder : Json.Decode.Decoder TextLockResp
textLockRespDecoder =
    Json.Decode.succeed TextLockResp
        |> required "locked" Json.Decode.bool


textDifficultiesDecoder : Json.Decode.Decoder (List TextDifficulty)
textDifficultiesDecoder =
    Json.Decode.list textDifficultyDecoder


textDifficultyDecoder : Json.Decode.Decoder TextDifficulty
textDifficultyDecoder =
    Utils.stringTupleDecoder


decodeRespErrors : String -> Result Json.Decode.Error TextsRespError
decodeRespErrors str =
    Json.Decode.decodeString (Json.Decode.field "errors" (Json.Decode.dict Json.Decode.string)) str
