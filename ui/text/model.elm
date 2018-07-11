module Text.Model exposing (Text, TextDifficulty, emptyText)

import Question.Model
import Field

import Date exposing (Date)
import Array exposing (Array)

type alias Text = {
    id: Maybe Field.ID
  , title: String
  , created_dt: Maybe Date
  , modified_dt: Maybe Date
  , source: String
  , difficulty: String
  , author: String
  , question_count : Int
  , questions : Array Question.Model.Question
  , body : String }

type alias TextDifficulty = (String, String)

emptyText : Text
emptyText = {
    id = Nothing
  , title = ""
  , created_dt = Nothing
  , modified_dt = Nothing
  , source = ""
  , difficulty = ""
  , author = ""
  , question_count = 0
  , questions = Question.Model.initial_questions
  , body = "" }