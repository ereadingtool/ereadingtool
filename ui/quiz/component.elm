module Quiz.Component exposing (QuizComponent, emptyQuizComponent, text_components, set_text_components
  , quiz, set_quiz_attribute)

import Quiz.Model as Quiz exposing (Quiz)
import Text.Component.Group exposing (TextComponentGroup)


type alias QuizAttributeName = String

type QuizComponent = QuizComponent Quiz TextComponentGroup


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