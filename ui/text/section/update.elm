module Text.Update exposing (update, Msg(..), Field(..))

import Question.Field exposing (QuestionField)
import Answer.Field exposing (AnswerField)
import Quiz.Component as Quiz exposing (QuizComponent)

import Text.Component exposing (TextField, TextComponent)
import Text.Component.Group exposing (TextComponentGroup)
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
  ->   { a | quiz_component: QuizComponent}
  -> ( { a | quiz_component: QuizComponent}, Cmd msg )
update msg model =
  let
    text_components = Quiz.text_components model.quiz_component
    update = Text.Component.Group.update_text_components text_components >> Quiz.set_text_components model.quiz_component
  in case msg of
    -- text msgs
    AddText ->
      ({ model | quiz_component =
        Quiz.set_text_components model.quiz_component (Text.Component.Group.add_new_text text_components) }
      , Cmd.none)

    DeleteText text_component ->
      ({ model | quiz_component =
        Quiz.set_text_components model.quiz_component (Text.Component.Group.delete_text text_components text_component) }
      , Cmd.none)

    UpdateTextValue text_component field_name input ->
        ({ model | quiz_component = update
           (Text.Component.set_text text_component field_name input)  }, Cmd.none)

    UpdateTextBody (ckeditor_id, ckeditor_text) ->
        ({ model | quiz_component = Quiz.set_text_components model.quiz_component
           (Text.Component.Group.update_body_for_id text_components ckeditor_id ckeditor_text) }, Cmd.none)

    -- question msgs
    AddQuestion text_component ->
      ({ model | quiz_component = update (Text.Component.add_new_question text_component) }, Cmd.none)

    UpdateQuestionField text_component question_field ->
      ({ model | quiz_component = update (Text.Component.update_question_field text_component question_field) }, Cmd.none)

    UpdateQuestionFieldValue text_component question_field value ->
      ({ model | quiz_component = update
        (Text.Component.update_question_field text_component (Question.Field.set_question_body question_field value))
      }, Cmd.none)

    DeleteQuestion text_component question_field ->
        ({ model | quiz_component = update
           (Text.Component.delete_question_field text_component question_field)
        }, Cmd.none)

    SelectQuestion text_component question_field selected ->
        let
          new_question_field = Question.Field.set_selected question_field selected
        in
          ({ model | quiz_component = update
             (Text.Component.update_question_field text_component new_question_field)
          }, Cmd.none)

    DeleteSelectedQuestions text_component ->
        ({ model | quiz_component = update
           (Text.Component.delete_selected_question_fields text_component)
        }, Cmd.none)

    ToggleQuestionMenu text_component question_field ->
        ({ model | quiz_component = update
           (Text.Component.toggle_question_menu text_component question_field)
        }, Cmd.none)

    -- answer msgs
    UpdateAnswerField text_component answer_field ->
        ({ model | quiz_component = update (Text.Component.set_answer text_component answer_field)  }, Cmd.none)

    UpdateAnswerFieldValue text_component answer_field text ->
        ({ model | quiz_component = update (Text.Component.set_answer_text text_component answer_field text)  }, Cmd.none)

    UpdateAnswerFeedbackValue text_component answer_field feedback ->
          ({ model | quiz_component = update
           (Text.Component.set_answer_feedback text_component answer_field feedback)  }, Cmd.none)

    UpdateAnswerFieldCorrect text_component answer_field correct ->
          ({ model | quiz_component = update
            (Text.Component.set_answer_correct text_component answer_field)
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
        ({ model | quiz_component = update new_text_component }, Cmd.batch <| extra_cmds ++ [post_toggle_field field])

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
