module Text.Reading.Model exposing (..)

import Json.Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

type alias TextReading = {
    id: Int
  , text: String
  , current_section: Maybe String
  , status: String }


textReadingDecoder : Json.Decode.Decoder TextReading
textReadingDecoder =
  decode TextReading
    |> required "id" Json.Decode.int
    |> required "text" Json.Decode.string
    |> required "current_section" (Json.Decode.nullable (Json.Decode.string))
    |> required "status" Json.Decode.string

textReadingsDecoder : Json.Decode.Decoder (List TextReading)
textReadingsDecoder =
  Json.Decode.list textReadingDecoder
