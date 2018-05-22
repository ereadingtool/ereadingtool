module Quiz.Model exposing (Quiz, new_quiz, set_texts)

import Text.Model

import Array exposing (Array)

type alias Quiz = {
    id: Maybe Int
  , title: String
  , texts: Array Text.Model.Text }


new_quiz : Quiz
new_quiz = {id=Nothing, title="", texts=Array.fromList [Text.Model.emptyText]}

set_texts : Quiz -> Array Text.Model.Text -> Quiz
set_texts quiz texts = { quiz | texts = texts }
