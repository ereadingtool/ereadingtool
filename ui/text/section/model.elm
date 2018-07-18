module Text.Section.Model exposing (TextSection, emptyTextSection)

import Question.Model

import Array exposing (Array)

type alias TextSection = {
    order: Int
  , body : String
  , question_count : Int
  , questions : Array Question.Model.Question
  }

emptyTextSection : Int -> TextSection
emptyTextSection i =
  let
    initial_questions = Question.Model.initial_questions
  in
    { order = i
    , question_count = Array.length initial_questions
    , questions = initial_questions
    , body = "" }