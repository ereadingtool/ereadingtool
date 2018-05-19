module Quiz.Model exposing (Quiz, emptyQuiz, text_components, set_text_components, attributes, set_attributes)

import Text.Component.Group exposing (TextComponentGroup)

type alias QuizAttributes = {
   title: String }

type alias QuizAttributeName = String

type Quiz = Quiz QuizAttributes TextComponentGroup


attributes : Quiz -> QuizAttributes
attributes (Quiz attrs _) = attrs

set_attributes : Quiz -> QuizAttributeName -> String -> Quiz
set_attributes ((Quiz attrs components) as quiz) attr_name value =
  case attr_name of
    "title" -> Quiz { attrs | title = value } components
    _ -> quiz

emptyQuiz : Quiz
emptyQuiz =
  Quiz {title=""} (Text.Component.Group.new_group)

text_components : Quiz -> TextComponentGroup
text_components (Quiz _ components) =
  components

set_text_components : Quiz -> TextComponentGroup -> Quiz
set_text_components (Quiz attrs _) new_components =
  Quiz attrs new_components
