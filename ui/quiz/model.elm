module Quiz.Model exposing (Quiz, QuizListItem, new_quiz, set_texts, set_tags)

import Text.Model

import Date exposing (Date)
import Array exposing (Array)

type alias Quiz = {
    id: Maybe Int
  , title: String
  , introduction: String
  , created_by: Maybe String
  , last_modified_by: Maybe String
  , tags: Maybe (List String)
  , created_dt: Maybe Date
  , modified_dt: Maybe Date
  , texts: Array Text.Model.Text
  , write_locker: Maybe String }

type alias QuizListItem = {
    id: Int
  , title: String
  , created_by: String
  , last_modified_by: Maybe String
  , tags: Maybe (List String)
  , created_dt: Date
  , modified_dt: Date
  , text_count: Int
  , write_locker: Maybe String }

new_quiz : Quiz
new_quiz = {
    id=Nothing
  , title=""
  , introduction=""
  , tags=Nothing
  , created_by=Nothing
  , last_modified_by=Nothing
  , created_dt=Nothing
  , modified_dt=Nothing
  , texts=Array.fromList [Text.Model.emptyText]
  , write_locker=Nothing }

set_texts : Quiz -> Array Text.Model.Text -> Quiz
set_texts quiz texts = { quiz | texts = texts }

set_tags : Quiz -> Maybe (List String) -> Quiz
set_tags quiz tags = { quiz | tags = tags }