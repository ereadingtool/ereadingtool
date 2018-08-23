module TextReader.Answer.Model exposing (..)

import TextReader exposing (TextItemAttributes, Selected, FeedbackViewable)

type alias AnswerCorrect = Bool

type alias Answer = {
    id: Int
  , question_id: Int
  , text: String
  , order: Int
  , answered_correctly: Maybe Bool
  , feedback: String }


type TextAnswer = TextAnswer Answer


gen_text_answer : Answer -> TextAnswer
gen_text_answer answer =
  TextAnswer answer

correct : TextAnswer -> Bool
correct text_answer =
  case (answer text_answer).answered_correctly of
    Just correct ->
      correct
    Nothing ->
      False

feedback_viewable : TextAnswer -> Bool
feedback_viewable text_answer =
  case (answer text_answer).answered_correctly of
    Just _ ->
      True
    Nothing ->
      False

selected : TextAnswer -> Bool
selected text_answer =
  case (answer text_answer).answered_correctly of
    Just _ ->
      True
    Nothing ->
      False

answer : TextAnswer -> Answer
answer (TextAnswer answer) = answer