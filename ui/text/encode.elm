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
    , ("tags", Encode.list
        (case quiz.tags of
          Just tags -> List.map (\tag -> Encode.string tag) tags
          _ -> []))
  ]
