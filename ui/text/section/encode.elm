module Text.Section.Encode exposing (textSectionEncoder, textSectionsEncoder)

import Text.Section.Model exposing (TextSection)
import Question.Encode

import Json.Encode as Encode

import Array exposing (Array)

textSectionEncoder : TextSection -> Encode.Value
textSectionEncoder text = Encode.object [
      ("body", Encode.string text.body)
    , ("questions", (Question.Encode.questionsEncoder text.questions))
  ]

textSectionsEncoder : Array TextSection -> Encode.Value
textSectionsEncoder texts =
     Encode.list
  <| Array.toList
  <| Array.map (\text -> textSectionEncoder text) texts