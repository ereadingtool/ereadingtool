module TextReader.Section.Model exposing (..)

import Array exposing (Array)
import TextReader.Question.Model exposing (TextQuestion, Question)


type Section = Section TextSection (Array TextQuestion)

type alias TextSection = {
    order : Int
  , body : String
  , question_count : Int
  , questions : Array TextReader.Question.Model.Question
  , num_of_sections : Int }

emptyTextSection : TextSection
emptyTextSection = {
    order=0
  , body=""
  , question_count=0
  , questions=Array.fromList []
  , num_of_sections=0
  }

questions : Section -> Array TextQuestion
questions (Section _ questions) = questions

text_section : Section -> TextSection
text_section (Section text_section _) = text_section

newSection : TextSection -> Section
newSection text_section =
  Section text_section (Array.map TextReader.Question.Model.gen_text_question text_section.questions)

complete : Section -> Bool
complete section =
     List.all (\answered -> answered)
  <| Array.toList
  <| Array.map (\question -> TextReader.Question.Model.answered question) (questions section)

completed_sections : Array Section -> Int
completed_sections sections =
     List.sum
  <| Array.toList
  <| Array.map (\section -> if (complete section) then 1 else 0) sections

max_score : Section -> Int
max_score section =
     List.sum
  <| Array.toList
  <| Array.map (\question -> 1) (questions section)

score : Section -> Int
score section =
     List.sum
  <| Array.toList
  <| Array.map (\question ->
       if (Maybe.withDefault False (TextReader.Question.Model.answered_correctly question)) then 1 else 0) (questions section)
