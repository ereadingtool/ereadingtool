module Text.Update exposing (update, Msg(..), Field(..))

import Question.Field exposing (QuestionField)
import Answer.Field exposing (AnswerField)

import Text.Component exposing (TextField, TextComponent)
import Text.Component.Group exposing (TextComponentGroup)
import Ports exposing (selectAllInputText)

type Field = Text TextField | Question QuestionField | Answer AnswerField

type Msg =
  -- text msgs
    UpdateTextValue TextComponent String String
  | AddText

  -- question msgs
  | UpdateQuestionField TextComponent Question.Field.QuestionField
  | UpdateQuestionFieldValue TextComponent Question.Field.QuestionField String
  | ToggleQuestionMenu TextComponent Question.Field.QuestionField
  | DeleteQuestion TextComponent Question.Field.QuestionField
  | AddQuestion TextComponent

  -- answer msgs
  | UpdateAnswerField TextComponent Answer.Field.AnswerField
  | UpdateAnswerFieldValue TextComponent Answer.Field.AnswerField String
  | UpdateAnswerFeedbackValue TextComponent Answer.Field.AnswerField String
  | UpdateAnswerFieldCorrect TextComponent Answer.Field.AnswerField Bool

  -- UI effects-related messages
  | ToggleEditable TextComponent Field


update : Msg
  ->   { a | text_components: TextComponentGroup}
  -> ( { a | text_components: TextComponentGroup}, Cmd msg )
update msg model =
  let
    update = Text.Component.Group.update_text_components model.text_components
  in case msg of
    -- text msgs
    AddText ->
      ({ model | text_components = Text.Component.Group.add_new_text model.text_components }, Cmd.none)

    UpdateTextValue text_component field_name input ->
        ({ model | text_components = update
           (Text.Component.set_text text_component field_name input)  }, Cmd.none)

    -- question msgs
    AddQuestion text_component ->
      ({ model | text_components = update (Text.Component.add_new_question text_component) }, Cmd.none)

    UpdateQuestionField text_component question_field ->
      ({ model | text_components = update (Text.Component.update_question_field text_component question_field) }, Cmd.none)

    UpdateQuestionFieldValue text_component question_field value ->
      ({ model | text_components = update
        (Text.Component.update_question_field text_component (Question.Field.set_question_body question_field value))
      }, Cmd.none)

    DeleteQuestion text_component question_field ->
        ({ model | text_components = update
           (Text.Component.delete_question_field text_component question_field)
        }, Cmd.none)

    ToggleQuestionMenu text_component question_field ->
        ({ model | text_components = update
           (Text.Component.toggle_question_menu text_component question_field)
        }, Cmd.none)

    -- answer msgs
    UpdateAnswerField text_component answer_field ->
        ({ model | text_components = update (Text.Component.set_answer text_component answer_field)  }, Cmd.none)

    UpdateAnswerFieldValue text_component answer_field text ->
        ({ model | text_components = update (Text.Component.set_answer_text text_component answer_field text)  }, Cmd.none)

    UpdateAnswerFeedbackValue text_component answer_field feedback ->
          ({ model | text_components = update
           (Text.Component.set_answer_feedback text_component answer_field feedback)  }, Cmd.none)

    UpdateAnswerFieldCorrect text_component answer_field correct ->
          ({ model | text_components = update
            (Text.Component.set_answer_correct text_component answer_field)
          }, Cmd.none)

    -- ui msgs
    ToggleEditable text_component field ->
      let
        new_text_component = (
          case field of
            Text field -> Text.Component.set_field text_component (Text.Component.switch_editable field) field.name
            Question field -> Text.Component.set_question text_component (Question.Field.switch_editable field)
            Answer field -> Text.Component.set_answer text_component (Answer.Field.switch_editable field))
      in
        ({ model | text_components = update new_text_component }, post_toggle_field field)

post_toggle_field : Field -> Cmd msg
post_toggle_field field =
  let
    (field_editable, field_id) =
      case field of
        Text field -> (field.editable, field.id)
        Question field -> (Question.Field.editable field, Question.Field.id field)
        Answer field -> (Answer.Field.editable field, Answer.Field.id field)
  in
    if (not field_editable) then selectAllInputText field_id else Cmd.none
