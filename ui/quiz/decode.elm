module Quiz.Decode exposing (quizDecoder)

import Quiz.Model exposing (Quiz)
import Text.Decode

import Array exposing (Array)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)


quizDecoder : Decode.Decoder Quiz
quizDecoder =
  decode Quiz
    |> required "id" (Decode.nullable (Decode.int))
    |> required "title" (Decode.string)
    |> required "texts" (Decode.map Array.fromList (Text.Decode.textsDecoder))
