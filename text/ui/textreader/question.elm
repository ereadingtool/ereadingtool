module TextReader.Question exposing (..)

import Array exposing (Array)

import TextReader exposing (TextItemAttributes, AnsweredCorrectly)
import TextReader.Answer exposing (TextAnswer, Answer)

import Date exposing (Date)


type alias Question = {
    id: Int
  , text_section_id: Int
  , created_dt: Maybe Date
  , modified_dt: Maybe Date
  , body: String
  , order: Int
  , answers: Array Answer
  , question_type: String }

type TextQuestion = TextQuestion Question (Array TextAnswer)

gen_text_question : Question -> TextQuestion
gen_text_question question =
  TextQuestion question
    (Array.map (TextReader.Answer.gen_text_answer) question.answers)

answered : TextQuestion -> Bool
answered text_question =
  case (answered_correctly text_question) of
    Just _ ->
      True
    Nothing ->
      False

question : TextQuestion -> Question
question (TextQuestion question _) = question

answers : TextQuestion -> Array TextAnswer
answers (TextQuestion _ answers) = answers

answered_correctly : TextQuestion -> Maybe Bool
answered_correctly (TextQuestion _ _) = Just False

