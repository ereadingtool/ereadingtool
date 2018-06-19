module Quiz.Component exposing (QuizComponent, emptyQuizComponent, text_components, set_text_components
  , quiz, set_quiz_attribute, init, update_quiz_errors, reinitialize_ck_editors, set_title_editable
  , set_intro_editable, QuizViewParams, quiz_fields)

import Quiz.Model as Quiz exposing (Quiz)
import Quiz.Field exposing (QuizFields, init_quiz_fields, QuizIntro, QuizTitle, QuizTags)

import Text.Component.Group exposing (TextComponentGroup)

import Dict exposing (Dict)
import Ports exposing (ckEditor, ckEditorSetHtml, CKEditorID, CKEditorText, addClassToCKEditor, selectAllInputText)

type alias QuizAttributeName = String

type alias QuizViewParams = {
    quiz: Quiz
  , quiz_component: QuizComponent }

type QuizComponent = QuizComponent Quiz QuizFields TextComponentGroup

init : Quiz -> QuizComponent
init quiz =
  QuizComponent quiz init_quiz_fields (Text.Component.Group.fromTexts quiz.texts)

quiz : QuizComponent -> Quiz
quiz (QuizComponent quiz _ component_group) =
  Quiz.set_texts quiz (Text.Component.Group.toTexts component_group)

quiz_fields : QuizComponent -> QuizFields
quiz_fields (QuizComponent _ quiz_fields _) =
  quiz_fields

set_quiz_fields : QuizComponent -> QuizFields -> QuizComponent
set_quiz_fields quiz_component quiz_fields =
  quiz_component

set_intro_editable : QuizComponent -> Bool -> QuizComponent
set_intro_editable (QuizComponent quiz quiz_fields component_group) editable =
  let
    (Quiz.Field.QuizIntro intro_field_attrs) = Quiz.Field.intro quiz_fields
  in
    QuizComponent quiz (Quiz.Field.set_intro quiz_fields { intro_field_attrs | editable = editable }) component_group

set_title_editable : QuizComponent -> Bool -> QuizComponent
set_title_editable (QuizComponent quiz quiz_fields component_group) editable =
  let
    (Quiz.Field.QuizTitle title_field_attrs) = Quiz.Field.title quiz_fields
  in
    QuizComponent quiz (Quiz.Field.set_title quiz_fields { title_field_attrs | editable = editable }) component_group


text_components : QuizComponent -> TextComponentGroup
text_components (QuizComponent _ _ components) =
  components

set_text_components : QuizComponent -> TextComponentGroup -> QuizComponent
set_text_components (QuizComponent quiz fields _) new_components =
  QuizComponent quiz fields new_components

set_quiz_attribute : QuizComponent -> QuizAttributeName -> String -> QuizComponent
set_quiz_attribute ((QuizComponent quiz fields components) as quiz_component) attr_name value =
  case attr_name of
    "title" -> QuizComponent { quiz | title = value } fields components
    "introduction" -> QuizComponent { quiz | introduction = value } fields components
    _ -> quiz_component

emptyQuizComponent : QuizComponent
emptyQuizComponent =
  QuizComponent Quiz.new_quiz init_quiz_fields (Text.Component.Group.new_group)

reinitialize_ck_editors : QuizComponent -> Cmd msg
reinitialize_ck_editors ((QuizComponent quiz fields components) as quiz_component) =
  let
    text_component_group = text_components quiz_component
  in
    Cmd.batch [
      Cmd.batch [ckEditor "quiz_introduction", ckEditorSetHtml ("quiz_introduction", quiz.introduction)]
    , Text.Component.Group.reinitialize_ck_editors text_component_group ]

update_quiz_errors : QuizComponent -> Dict String String -> QuizComponent
update_quiz_errors quiz_component errors =
  let
    _ = (Debug.log "quiz errors" errors)
    new_text_components =
      Text.Component.Group.update_errors (text_components quiz_component) errors
  in
    (set_text_components quiz_component new_text_components)
