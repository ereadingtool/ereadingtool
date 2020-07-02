module Text.Section.Decode exposing (textSectionDecoder, textSectionsDecoder, TextCreateResp)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)

import Question.Decode

import Text.Section.Model exposing (TextSection)
import Field

type alias TextCreateResp = { id: Maybe Field.ID }


textSectionDecoder : Decode.Decoder TextSection
textSectionDecoder =
  decode TextSection
    |> required "order" Decode.int
    |> required "body" Decode.string
    |> required "question_count" Decode.int
    |> required "questions" Question.Decode.questionsDecoder

textSectionsDecoder : Decode.Decoder (List TextSection)
textSectionsDecoder = Decode.list textSectionDecoder

