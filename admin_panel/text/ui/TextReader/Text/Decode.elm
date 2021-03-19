module TextReader.Text.Decode exposing (..)

import Json.Decode

import TextReader.Text.Model exposing (Text)

import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)
import Json.Decode.Extra exposing (date)


textDecoder : Json.Decode.Decoder Text
textDecoder =
  decode Text
    |> required "id" (Json.Decode.int)
    |> required "title" (Json.Decode.string)
    |> required "introduction" (Json.Decode.string)
    |> required "author" (Json.Decode.string)
    |> required "source" (Json.Decode.string)
    |> required "difficulty" (Json.Decode.string)
    |> required "conclusion" (Json.Decode.nullable (Json.Decode.string))
    |> required "created_by" (Json.Decode.nullable (Json.Decode.string))
    |> required "last_modified_by" (Json.Decode.nullable (Json.Decode.string))
    |> required "tags" (Json.Decode.nullable (Json.Decode.list (Json.Decode.string)))
    |> required "created_dt" (Json.Decode.nullable date)
    |> required "modified_dt" (Json.Decode.nullable date)
