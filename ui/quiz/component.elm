module Quiz.Component exposing (QuizComponent, init_from_json, emptyQuizComponent, text_components, set_text_components
  , quiz, set_quiz_attribute)

import Quiz.Model as Quiz exposing (Quiz)
import Quiz.Decode

import Text.Component.Group exposing (TextComponentGroup)

import Json.Encode
import Json.Decode

type alias QuizAttributeName = String

type QuizComponent = QuizComponent Quiz TextComponentGroup


init_from_json : Json.Encode.Value -> QuizComponent
init_from_json quiz_json = case Json.Decode.decodeValue Quiz.Decode.quizDecoder quiz_json of
  Ok quiz -> init quiz
  Err err -> emptyQuizComponent

init : Quiz -> QuizComponent
init quiz =
  QuizComponent quiz (Text.Component.Group.fromTexts quiz.texts)

quiz : QuizComponent -> Quiz
quiz (QuizComponent quiz component_group) =
  Quiz.set_texts quiz (Text.Component.Group.toTexts component_group)

text_components : QuizComponent -> TextComponentGroup
text_components (QuizComponent _ components) =
  components

set_text_components : QuizComponent -> TextComponentGroup -> QuizComponent
set_text_components (QuizComponent quiz _) new_components =
  QuizComponent quiz new_components

set_quiz_attribute : QuizComponent -> QuizAttributeName -> String -> QuizComponent
set_quiz_attribute ((QuizComponent quiz components) as quiz_component) attr_name value =
  case attr_name of
    "title" -> QuizComponent { quiz | title = value } components
    _ -> quiz_component

emptyQuizComponent : QuizComponent
emptyQuizComponent =
  QuizComponent Quiz.new_quiz (Text.Component.Group.new_group)