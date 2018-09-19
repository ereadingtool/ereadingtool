module Text.Reading.Model exposing (..)

import Json.Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)


type alias TextReadingScore = {
   num_of_sections: Int
 , complete_sections: Int
 , section_scores: Int
 , possible_section_scores: Int }

type alias TextReading = {
    id: Int
  , text_id: Int
  , text: String
  , current_section: Maybe String
  , status: String
  , score: TextReadingScore }

textReadingScoreDecoder : Json.Decode.Decoder TextReadingScore
textReadingScoreDecoder =
  decode TextReadingScore
    |> required "num_of_sections" Json.Decode.int
    |> required "complete_sections" Json.Decode.int
    |> required "section_scores" Json.Decode.int
    |> required "possible_section_scores" Json.Decode.int

textReadingDecoder : Json.Decode.Decoder TextReading
textReadingDecoder =
  decode TextReading
    |> required "id" Json.Decode.int
    |> required "text_id" Json.Decode.int
    |> required "text" Json.Decode.string
    |> required "current_section" (Json.Decode.nullable (Json.Decode.string))
    |> required "status" Json.Decode.string
    |> required "score" textReadingScoreDecoder

textReadingsDecoder : Json.Decode.Decoder (List TextReading)
textReadingsDecoder =
  Json.Decode.list textReadingDecoder
