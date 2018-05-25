module Quiz.Component exposing (QuizComponent, emptyQuizComponent, text_components, set_text_components
  , quiz, set_quiz_attribute, init, update_quiz_errors, reinitialize_ck_editors)

import Quiz.Model as Quiz exposing (Quiz)

import Text.Component.Group exposing (TextComponentGroup)

import Dict exposing (Dict)

type alias QuizAttributeName = String

type QuizComponent = QuizComponent Quiz TextComponentGroup


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

reinitialize_ck_editors : QuizComponent -> Cmd msg
reinitialize_ck_editors quiz_component =
  let
    text_component_group = text_components quiz_component
  in
    Text.Component.Group.reinitialize_ck_editors text_component_group

update_quiz_errors : QuizComponent -> Dict String String -> QuizComponent
update_quiz_errors quiz_component errors =
  let
    _ = (Debug.log "quiz errors" errors)
    new_text_components =
      Text.Component.Group.update_errors (text_components quiz_component) errors
  in
    (set_text_components quiz_component new_text_components)
