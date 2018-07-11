module Text.Encode exposing (textEncoder, textsEncoder)

import Text.Model exposing (Text)
import Question.Encode

import Json.Encode as Encode

import Array exposing (Array)

textEncoder : Text -> Encode.Value
textEncoder text = Encode.object [
   ("body", Encode.string text.body)
 , ("questions", (Question.Encode.questionsEncoder text.questions))
 ]

textsEncoder : Array Text -> Encode.Value
textsEncoder texts =
     Encode.list
  <| Array.toList
  <| Array.map (\text -> textEncoder text) texts