module Answer.Decode exposing (answerDecoder, answersDecoder)

import Answer.Model exposing (Answer)
import Array exposing (Array)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required, resolve)


answerDecoder : Decode.Decoder Answer
answerDecoder =
    decode Answer
        |> required "id" (Decode.nullable Decode.int)
        |> required "question_id" (Decode.nullable Decode.int)
        |> required "text" Decode.string
        |> required "correct" Decode.bool
        |> required "order" Decode.int
        |> required "feedback" Decode.string


answersDecoder : Decode.Decoder (Array Answer)
answersDecoder =
    Decode.array answerDecoder
