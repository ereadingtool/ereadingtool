module Text.Model exposing (Text, TextDifficulty, emptyText)

import Question.Model
import Field

import Date exposing (Date)
import Array exposing (Array)

type alias Text = {
    order: Int
  , body : String
  , question_count : Int
  , questions : Array Question.Model.Question
  }

type alias TextDifficulty = (String, String)

emptyText : Text
emptyText = {
    order = 0
  , question_count = 0
  , questions = Question.Model.initial_questions
  , body = "" }