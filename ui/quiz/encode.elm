module Quiz.Encode exposing (quizEncoder)

import Quiz.Model as Quiz exposing (Quiz)
import Text.Encode exposing (textsEncoder)

import Text.Component.Group
import Json.Encode as Encode

quizEncoder : Quiz -> Encode.Value
quizEncoder quiz =
  let
    attrs = Quiz.attributes quiz
    text_group = Quiz.text_components quiz
  in
    Encode.object [
        ("title", Encode.string attrs.title)
      , ("texts", textsEncoder <| Text.Component.Group.toTexts text_group)
    ]
