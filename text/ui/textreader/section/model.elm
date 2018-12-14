module TextReader.Section.Model exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)

import Text.Model

import TextReader.Question.Model exposing (TextQuestion, Question)


type Section = Section TextSection (Array TextQuestion)

type alias TextSection = {
    order : Int
  , body : String
  , question_count : Int
  , questions : Array TextReader.Question.Model.Question
  , num_of_sections : Int
  , translations : Text.Model.Words }

emptyTextSection : TextSection
emptyTextSection = {
    order=0
  , body=""
  , question_count=0
  , questions=Array.fromList []
  , num_of_sections=0
  , translations=Dict.empty
  }

questions : Section -> Array TextQuestion
questions (Section _ questions) = questions

textSection : Section -> TextSection
textSection (Section text_section _) = text_section

translations : Section -> Text.Model.Words
translations (Section text_section _) = text_section.translations

newSection : TextSection -> Section
newSection text_section =
  Section text_section (Array.map TextReader.Question.Model.gen_text_question text_section.questions)

complete : Section -> Bool
complete section =
     List.all (\answered -> answered)
  <| Array.toList
  <| Array.map (\question -> TextReader.Question.Model.answered question) (questions section)

completedSections : Array Section -> Int
completedSections sections =
     List.sum
  <| Array.toList
  <| Array.map (\section -> if (complete section) then 1 else 0) sections

maxScore : Section -> Int
maxScore section =
     List.sum
  <| Array.toList
  <| Array.map (\question -> 1) (questions section)

score : Section -> Int
score section =
     List.sum
  <| Array.toList
  <| Array.map (\question ->
       if (Maybe.withDefault False (TextReader.Question.Model.answered_correctly question)) then 1 else 0) (questions section)
