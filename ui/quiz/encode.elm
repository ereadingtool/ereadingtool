module Quiz.Encode exposing (quizEncoder)

import Quiz.Model
import Quiz.Component exposing (QuizComponent)
import Text.Encode exposing (textsEncoder)

import Text.Component.Group
import Json.Encode as Encode

quizEncoder : Quiz.Model.Quiz -> Encode.Value
quizEncoder quiz =
  Encode.object [
      ("title", Encode.string quiz.title)
    , ("texts", textsEncoder quiz.texts)
  ]
