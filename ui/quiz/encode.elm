module Quiz.Encode exposing (quizEncoder)

import Quiz.Model
import Text.Encode exposing (textsEncoder)

import Json.Encode as Encode

quizEncoder : Quiz.Model.Quiz -> Encode.Value
quizEncoder quiz =
  Encode.object [
      ("introduction", Encode.string quiz.introduction)
    , ("title", Encode.string quiz.title)
    , ("texts", textsEncoder quiz.texts)
  ]
