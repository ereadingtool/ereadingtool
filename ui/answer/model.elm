module Answer.Model exposing (Answer, generate_answer, generate_answers)

import Array exposing (Array)

type alias Answer = {
    id: Maybe Int
  , question_id: Maybe Int
  , text: String
  , correct: Bool
  , order: Int
  , feedback: String }

generate_answer : Int -> Answer
generate_answer i = {
    id=Nothing
  , question_id=Nothing
  , text=String.join " " ["Click to write choice", toString (i+1)]
  , correct=False
  , order=i
  , feedback="" }

generate_answers : Int -> Array Answer
generate_answers n =
     Array.fromList
  <| List.map generate_answer
  <| List.range 0 (n-1)
