module Text.Update exposing (update, Msg(..), Field(..))

import Question.Field exposing (QuestionField)
import Answer.Field exposing (AnswerField)
import Text.Component as Text exposing (TextComponent)

import Text.Component exposing (TextField, TextComponent)
import Text.Section.Component exposing (TextSectionComponent)

import Text.Section.Component.Group exposing (TextSectionComponentGroup)
import Ports exposing (selectAllInputText, ckEditor, CKEditorID, CKEditorText)

type Field = Text TextField | Question QuestionField | Answer AnswerField

type Msg =
  -- text msgs
    UpdateTextValue TextSectionComponent String String
  | AddText
  | DeleteText TextSectionComponent
  | UpdateTextBody (CKEditorID, CKEditorText)

  -- question msgs
  | UpdateQuestionField TextSectionComponent Question.Field.QuestionField
  | UpdateQuestionFieldValue TextSectionComponent Question.Field.QuestionField String
  | ToggleQuestionMenu TextSectionComponent Question.Field.QuestionField
  | DeleteQuestion TextSectionComponent Question.Field.QuestionField
  | SelectQuestion TextSectionComponent Question.Field.QuestionField Bool
  | DeleteSelectedQuestions TextSectionComponent
  | AddQuestion TextSectionComponent

  -- answer msgs
  | UpdateAnswerField TextSectionComponent Answer.Field.AnswerField
  | UpdateAnswerFieldValue TextSectionComponent Answer.Field.AnswerField String
  | UpdateAnswerFeedbackValue TextSectionComponent Answer.Field.AnswerField String
  | UpdateAnswerFieldCorrect TextSectionComponent Answer.Field.AnswerField Bool

  -- UI effects-related messages
  | ToggleEditable TextSectionComponent Field


update : Msg
  ->   { a | text_component: TextComponent}
  -> ( { a | text_component: TextComponent}, Cmd msg )
update msg model =
  let
    text_section_components = Text.text_section_components model.text_component
    update =
         Text.Section.Component.Group.update_section_components text_section_components
      >> Text.set_text_section_components model.text_component
  in case msg of
    -- text msgs
    AddText ->
      ({ model | text_component =
        Text.set_text_section_components model.text_component
          (Text.Section.Component.Group.add_new_text_section text_section_components) }
      , Cmd.none)

    DeleteText text_component ->
      ({ model | text_component =
        Text.set_text_section_components model.text_component
          (Text.Section.Component.Group.delete_text_section text_section_components text_component) }
      , Cmd.none)

    UpdateTextValue text_component field_name input ->
        ({ model | text_component = update
           (Text.Component.set_text text_component field_name input)  }, Cmd.none)

    UpdateTextBody (ckeditor_id, ckeditor_text) ->
        ({ model | text_component = Text.set_text_section_components model.text_component
             (Text.Section.Component.Group.update_body_for_id text_section_components ckeditor_id ckeditor_text) }
           , Cmd.none)

    -- question msgs
    AddQuestion text_section ->
      ({ model | text_component =
          update (Text.Section.Component.add_new_question text_section) }, Cmd.none)

    UpdateQuestionField text_section question_field ->
      ({ model | text_component =
          update (Text.Section.Component.update_question_field text_section question_field) }, Cmd.none)

    UpdateQuestionFieldValue text_section question_field value ->
      ({ model | text_component = update
        (Text.Section.Component.update_question_field text_section
          (Question.Field.set_question_body question_field value))
      }, Cmd.none)

    DeleteQuestion text_section question_field ->
        ({ model | text_component = update
           (Text.Section.Component.delete_question_field text_section question_field)
        }, Cmd.none)

    SelectQuestion text_section question_field selected ->
        let
          new_question_field = Question.Field.set_selected question_field selected
        in
          ({ model | text_component = update
             (Text.Section.Component.update_question_field text_section new_question_field)
          }, Cmd.none)

    DeleteSelectedQuestions text_section ->
        ({ model | text_component = update
           (Text.Section.Component.delete_selected_question_fields text_section)
        }, Cmd.none)

    ToggleQuestionMenu text_section question_field ->
        ({ model | text_component = update
           (Text.Section.Component.toggle_question_menu text_section question_field)
        }, Cmd.none)

    -- answer msgs
    UpdateAnswerField text_section answer_field ->
        ({ model | text_component =
            update (Text.Section.Component.set_answer text_section answer_field)  }, Cmd.none)

    UpdateAnswerFieldValue text_section answer_field text ->
        ({ model | text_component =
            update (Text.Section.Component.set_answer_text text_section answer_field text)  }, Cmd.none)

    UpdateAnswerFeedbackValue text_section answer_field feedback ->
          ({ model | text_component =
            update (Text.Section.Component.set_answer_feedback text_section answer_field feedback)  }, Cmd.none)

    UpdateAnswerFieldCorrect text_section answer_field correct ->
          ({ model | text_component = update
            (Text.Section.Component.set_answer_correct text_section answer_field)
          }, Cmd.none)

    -- ui msgs
    ToggleEditable text_component field ->
      let
        extra_cmds = (case field of
          Text text_field -> Text.Component.post_toggle_commands text_field
          _ -> [Cmd.none])
        new_text_component = (
          case field of
            Text field -> Text.Component.set_field text_component (Text.Component.switch_editable field)
            Question field -> Text.Component.set_question text_component (Question.Field.switch_editable field)
            Answer field -> Text.Component.set_answer text_component (Answer.Field.switch_editable field))
      in
        ({ model | text_component = update new_text_component }, Cmd.batch <| extra_cmds ++ [post_toggle_field field])

post_toggle_field : Field -> Cmd msg
post_toggle_field field =
  let
    (field_editable, field_id) =
      case field of
        Text field -> (Text.Component.editable field, Text.Component.text_field_id field)
        Question field -> (Question.Field.editable field, Question.Field.id field)
        Answer field -> (Answer.Field.editable field, Answer.Field.id field)
  in
    if (not field_editable) then selectAllInputText field_id else Cmd.none
