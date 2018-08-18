module TextReader.Answer exposing (..)

import TextReader exposing (TextItemAttributes, Selected, FeedbackViewable)

type alias Answer = {
    id: Int
  , question_id: Int
  , text: String
  , order: Int
  , feedback: String }


type TextAnswer = TextAnswer Answer Selected FeedbackViewable


gen_text_answer : Answer -> TextAnswer
gen_text_answer answer =
  TextAnswer answer False False

correct : TextAnswer -> Bool
correct text_answer =
  False

feedback_viewable : TextAnswer -> Bool
feedback_viewable (TextAnswer _ _ viewable) = viewable

selected : TextAnswer -> Bool
selected (TextAnswer _ selected _) = selected

answer : TextAnswer -> Answer
answer (TextAnswer answer _ _) = answer

set_answer_selected : TextAnswer -> Bool -> TextAnswer
set_answer_selected (TextAnswer answer _ feedback_viewable) selected =
  TextAnswer answer selected feedback_viewable

set_answer_feedback_viewable : TextAnswer -> Bool -> TextAnswer
set_answer_feedback_viewable (TextAnswer answer selected _) feedback_viewable =
  TextAnswer answer selected feedback_viewable
