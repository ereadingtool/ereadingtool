module Answer.Decode exposing (answerDecoder, answersDecoder)

import Answer.Model exposing (Answer)
import Array exposing (Array)
import Json.Decode
import Json.Decode.Pipeline exposing (required)


answerDecoder : Json.Decode.Decoder Answer
answerDecoder =
    Json.Decode.succeed Answer
        |> required "id" (Json.Decode.nullable Json.Decode.int)
        |> required "question_id" (Json.Decode.nullable Json.Decode.int)
        |> required "text" Json.Decode.string
        |> required "correct" Json.Decode.bool
        |> required "order" Json.Decode.int
        |> required "feedback" Json.Decode.string


answersDecoder : Json.Decode.Decoder (Array Answer)
answersDecoder =
    Json.Decode.array answerDecoder
