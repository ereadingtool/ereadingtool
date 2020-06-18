module Question.Decode exposing (questionDecoder, questionsDecoder)

import Answer.Decode
import Array exposing (Array)
import Json.Decode as Decode
import Json.Decode.Extra exposing (date)
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required, resolve)
import Question.Model exposing (Question)


questionDecoder : Decode.Decoder Question
questionDecoder =
    decode Question
        |> required "id" (Decode.nullable Decode.int)
        |> required "text_section_id" (Decode.nullable Decode.int)
        |> required "created_dt" (Decode.nullable date)
        |> required "modified_dt" (Decode.nullable date)
        |> required "body" Decode.string
        |> required "order" Decode.int
        |> required "answers" Answer.Decode.answersDecoder
        |> required "question_type" Decode.string


questionsDecoder : Decode.Decoder (Array Question)
questionsDecoder =
    Decode.array questionDecoder
