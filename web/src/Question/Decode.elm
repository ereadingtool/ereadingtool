module Question.Decode exposing (questionDecoder, questionsDecoder)

import Answer.Decode
import Array exposing (Array)
import Iso8601
import Json.Decode
import Json.Decode.Pipeline exposing (required)
import Question.Model exposing (Question)


questionDecoder : Json.Decode.Decoder Question
questionDecoder =
    Json.Decode.succeed Question
        |> required "id" (Json.Decode.nullable Json.Decode.int)
        |> required "text_section_id" (Json.Decode.nullable Json.Decode.int)
        |> required "created_dt" (Json.Decode.nullable Iso8601.decoder)
        |> required "modified_dt" (Json.Decode.nullable Iso8601.decoder)
        |> required "body" Json.Decode.string
        |> required "order" Json.Decode.int
        |> required "answers" Answer.Decode.answersDecoder
        |> required "question_type" Json.Decode.string


questionsDecoder : Json.Decode.Decoder (Array Question)
questionsDecoder =
    Json.Decode.array questionDecoder
