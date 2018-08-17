module TextReader.Answer exposing (..)

import TextReader exposing (TextItemAttributes, Selected, FeedbackViewable)

type alias Answer = {
    id: Int
  , question_id: Int
  , text: String
  , order: Int
  , feedback: String }

type alias TextAnswerAttributes = TextItemAttributes { question_index : Int, name: String, id: String }

type TextAnswer = TextAnswer Answer TextAnswerAttributes Selected FeedbackViewable


gen_text_answer : Int -> Int -> Int -> Answer -> TextAnswer
gen_text_answer text_section_index question_index answer_index answer =
  let
    answer_id = String.join "_"
      ["section", toString text_section_index, "question", (toString question_index), "answer"]
  in
    TextAnswer answer {
      -- question_field_index = question.order
      id = answer_id
    , name = answer_id
    , question_index = question_index
    , index = answer_index } False False

index : TextAnswer -> Int
index text_answer =
  (attr text_answer).index

correct : TextAnswer -> Bool
correct text_answer =
  False

feedback_viewable : TextAnswer -> Bool
feedback_viewable (TextAnswer _ _ _ viewable) = viewable

attr : TextAnswer -> TextAnswerAttributes
attr (TextAnswer _ attr _ _) = attr

selected : TextAnswer -> Bool
selected (TextAnswer _ _ selected _) = selected

answer : TextAnswer -> Answer
answer (TextAnswer answer _ _ _) = answer

set_answer_selected : TextAnswer -> Bool -> TextAnswer
set_answer_selected (TextAnswer answer attr _ feedback_viewable) selected =
  TextAnswer answer attr selected feedback_viewable

set_answer_feedback_viewable : TextAnswer -> Bool -> TextAnswer
set_answer_feedback_viewable (TextAnswer answer attr selected _) feedback_viewable =
  TextAnswer answer attr selected feedback_viewable
