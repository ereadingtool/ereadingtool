module TextReader.Answer.Model exposing (..)

import TextReader exposing (TextItemAttributes, Selected, FeedbackViewable)

type alias AnswerCorrect = Bool

type alias Answer = {
    id: Int
  , question_id: Int
  , text: String
  , order: Int
  , correct: Maybe Bool
  , feedback: String }


type TextAnswer = TextAnswer Answer Selected AnswerCorrect FeedbackViewable


gen_text_answer : Answer -> TextAnswer
gen_text_answer answer =
  TextAnswer answer False False False

correct : TextAnswer -> Bool
correct text_answer =
  False

feedback_viewable : TextAnswer -> Bool
feedback_viewable (TextAnswer _ _ _ viewable) = viewable

selected : TextAnswer -> Bool
selected (TextAnswer _ selected _ _) = selected

answer : TextAnswer -> Answer
answer (TextAnswer answer _ _ _) = answer

set_answer_selected : TextAnswer -> Bool -> TextAnswer
set_answer_selected (TextAnswer answer _ answer_correct feedback_viewable) selected =
  TextAnswer answer selected answer_correct feedback_viewable

set_answer_feedback_viewable : TextAnswer -> Bool -> TextAnswer
set_answer_feedback_viewable (TextAnswer answer selected answer_correct _) feedback_viewable =
  TextAnswer answer selected answer_correct feedback_viewable
