module Text.Update exposing (update, Msg(..), Field(..))

import Question.Field exposing (QuestionField)
import Answer.Field exposing (AnswerField)

import Array exposing (Array)
import Text.Component exposing (TextField, TextComponent)

type Field = Text TextField | Question QuestionField | Answer AnswerField

type Msg =
    UpdateTextValue TextComponent String String

  | UpdateTextField TextComponent Text.Component.TextField String
  | UpdateQuestionField TextComponent Question.Field.QuestionField
  | UpdateAnswerField TextComponent Answer.Field.AnswerField

  | ToggleEditable TextComponent Field
  | Hover TextComponent Field Bool



update : Msg
  -> {a | text_components: Array TextComponent}
  -> ( {a | text_components: Array TextComponent}, Cmd msg )
update msg model = case msg of
  UpdateTextValue text_component field_name input ->
    let
      index = Text.Component.index text_component
      new_text_component = Text.Component.set_text text_component field_name input
    in
      ({ model | text_components = Array.set index new_text_component model.text_components }, Cmd.none)

  UpdateTextField text_component new_field field_name ->
    let
      index = Text.Component.index text_component
      new_text_component = Text.Component.set_field text_component new_field field_name
    in
      ({ model | text_components = Array.set index new_text_component model.text_components }, Cmd.none)

  ToggleEditable text_component field ->
    let
      index = Text.Component.index text_component
      new_text_component = (
        case field of
          Text field -> Text.Component.set_field text_component (Text.Component.switch_editable field) field.name
          Question field -> Text.Component.set_question text_component (Question.Field.switch_editable field)
          Answer field -> Text.Component.set_answer text_component (Answer.Field.switch_editable field))
    in
      ({ model | text_components = Array.set index new_text_component model.text_components }, Cmd.none)

  Hover text_component field hover ->
    let
      index = Text.Component.index text_component
      new_text_component = (
        case field of
          Question field -> Text.Component.set_question text_component (Question.Field.hover field hover)
          Answer field -> Text.Component.set_answer text_component (Answer.Field.hover field hover)
          Text field -> Text.Component.set_field text_component { field | hover = hover} field.name )
    in
      ({ model | text_components = Array.set index new_text_component model.text_components }, Cmd.none)

  _ -> (model, Cmd.none)
