module Text.Section.Decode exposing (TextCreateResp, textSectionDecoder, textSectionsDecoder)

import Field
import Json.Decode
import Json.Decode.Pipeline exposing (required)
import Question.Decode
import Text.Section.Model exposing (TextSection)


type alias TextCreateResp =
    { id : Maybe Field.ID }


textSectionDecoder : Json.Decode.Decoder TextSection
textSectionDecoder =
    Json.Decode.succeed TextSection
        |> required "order" Json.Decode.int
        |> required "body" Json.Decode.string
        |> required "question_count" Json.Decode.int
        |> required "questions" Question.Decode.questionsDecoder


textSectionsDecoder : Json.Decode.Decoder (List TextSection)
textSectionsDecoder =
    Json.Decode.list textSectionDecoder
