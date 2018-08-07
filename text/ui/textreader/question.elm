module TextReader.Question exposing (..)

import Array exposing (Array)

import TextReader exposing (TextItemAttributes, AnsweredCorrectly)
import TextReader.Answer exposing (TextAnswer)

import Question.Model exposing (Question)

type alias TextQuestionAttributes = TextItemAttributes { id:String, text_section_index: Int }

type TextQuestion = TextQuestion Question TextQuestionAttributes (Maybe AnsweredCorrectly) (Array TextAnswer)

gen_text_question : Int -> Int -> Question -> TextQuestion
gen_text_question text_section_index index question =
  let
    question_id = String.join "_" ["section", toString text_section_index, "question", toString index]
  in
    TextQuestion question
      {index=index, text_section_index=text_section_index, id=question_id}
      Nothing (Array.indexedMap (TextReader.Answer.gen_text_answer text_section_index index) question.answers)

text_section_index : TextQuestion -> Int
text_section_index text_question =
  (attr text_question).text_section_index

index : TextQuestion -> Int
index text_question =
  (attr text_question).index

id : TextQuestion -> String
id text_question =
  toString <| (attr text_question).id

answered : TextQuestion -> Bool
answered text_question =
  case (answered_correctly text_question) of
    Just _ ->
      True
    Nothing ->
      False

deselect_all_answers : TextQuestion -> TextQuestion
deselect_all_answers text_question =
  let
    new_answers =
         Array.map (\ans -> TextReader.Answer.set_answer_feedback_viewable ans False)
      <| Array.map (\ans -> TextReader.Answer.set_answer_selected ans False) (answers text_question)
  in
    set_answers text_question new_answers

attr : TextQuestion -> TextQuestionAttributes
attr (TextQuestion _ attr _ _) = attr

question : TextQuestion -> Question
question (TextQuestion question _ _ _) = question

answers : TextQuestion -> Array TextAnswer
answers (TextQuestion _ _ _ answers) = answers

answered_correctly : TextQuestion -> Maybe Bool
answered_correctly (TextQuestion _ _ answered_correctly _) = answered_correctly

set_answered_correctly : TextQuestion -> Maybe Bool -> TextQuestion
set_answered_correctly (TextQuestion question question_attr _ answers) answered_correctly =
  TextQuestion question question_attr answered_correctly answers

set_answers : TextQuestion -> Array TextAnswer -> TextQuestion
set_answers (TextQuestion question question_attr ans_correctly _) new_answers =
  TextQuestion question question_attr ans_correctly new_answers

set_as_submitted_answer : TextQuestion -> TextAnswer -> TextQuestion
set_as_submitted_answer text_question text_answer =
  case (answered_correctly text_question) of
    Just _ ->
      -- already answered
      text_question
    Nothing ->
      -- set as the submitted answer
      let
        ans_correctly = Just <| (TextReader.Answer.correct text_answer) && (TextReader.Answer.selected text_answer)
      in
        set_answer (set_answered_correctly text_question ans_correctly) text_answer

set_answer : TextQuestion -> TextAnswer -> TextQuestion
set_answer (TextQuestion question question_attr answered_correctly answers) new_text_answer =
  let
    answer_index = TextReader.Answer.index new_text_answer
  in
    TextQuestion question question_attr answered_correctly (Array.set answer_index new_text_answer answers)
