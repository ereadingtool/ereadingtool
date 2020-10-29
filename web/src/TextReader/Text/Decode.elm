module TextReader.Text.Decode exposing (textDecoder)

import DateTime
import Iso8601
import Json.Decode
import Json.Decode.Extra exposing (posix)
import Json.Decode.Pipeline exposing (required)
import TextReader.Text.Model exposing (Text)


textDecoder : Json.Decode.Decoder Text
textDecoder =
    Json.Decode.succeed Text
        |> required "id" Json.Decode.int
        |> required "title" Json.Decode.string
        |> required "introduction" Json.Decode.string
        |> required "author" Json.Decode.string
        |> required "source" Json.Decode.string
        |> required "difficulty" Json.Decode.string
        |> required "conclusion" (Json.Decode.nullable Json.Decode.string)
        |> required "created_by" (Json.Decode.nullable Json.Decode.string)
        |> required "last_modified_by" (Json.Decode.nullable Json.Decode.string)
        |> required "tags" (Json.Decode.nullable (Json.Decode.list Json.Decode.string))
        |> required "created_dt" (Json.Decode.nullable (Json.Decode.map DateTime.fromPosix Iso8601.decoder))
        |> required "modified_dt" (Json.Decode.nullable (Json.Decode.map DateTime.fromPosix Iso8601.decoder))
