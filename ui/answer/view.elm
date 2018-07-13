module Answer.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Question.Model
import Answer.Field exposing (AnswerField)

import Text.Update exposing (..)
import Text.Section.Component exposing (TextSectionComponent)

import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Config exposing (answer_feedback_limit)

type alias AnswerFieldParams msg = {
    text_component: TextSectionComponent
  , question: Question.Model.Question
  , msg: (Text.Update.Msg -> msg) }


view_answer_feedback : (AnswerFieldParams msg) -> AnswerField -> List (Html msg)
view_answer_feedback params answer_field =
  let
    answer = Answer.Field.answer answer_field
  in
    if not (String.isEmpty answer.feedback) then
      [ Html.div [classList [("answer_feedback", True), ("grey_bg", True)] ] [ Html.text answer.feedback ] ]
    else
      []

view_answer : (AnswerFieldParams msg) -> AnswerField -> Html msg
view_answer params answer_field =
  let
    answer = Answer.Field.answer answer_field
  in
    Html.span [
       onClick (params.msg (ToggleEditable params.text_component (Answer answer_field)))
     , attribute "class" "editable"
   ] <| [ Html.text answer.text ] ++ (view_answer_feedback params answer_field)

edit_answer_feedback : (AnswerFieldParams msg) -> AnswerField -> Html msg
edit_answer_feedback params answer_field =
  let
    feedback_field = Answer.Field.feedback_field answer_field
    answer = Answer.Field.answer answer_field
  in
    Html.div [] [
        Html.textarea [
            attribute "id" feedback_field.id
          , attribute "rows" "5"
          , attribute "cols" "75"
          , onBlur (params.msg (ToggleEditable params.text_component (Answer answer_field)))
          , onInput (UpdateAnswerFeedbackValue params.text_component answer_field >> params.msg)
          , attribute "placeholder" "Give some feedback."
          , classList [ ("answer_feedback", True), ("input_error", feedback_field.error) ]
        ] [Html.text answer.feedback]
      , div [
        classList [
            ("chars_remaining", True)
          , ("error", (answer_feedback_limit - (String.length answer.feedback)) < 0)
        ] ] [
        Html.text
         <| "Characters remaining "
         ++ (toString (answer_feedback_limit - (String.length answer.feedback)))
         ++ "."
      , Html.text feedback_field.error_string ]
    ]

edit_answer : (AnswerFieldParams msg) -> AnswerField -> Html msg
edit_answer params answer_field =
  let
    answer = Answer.Field.answer answer_field
  in
    Html.span [] [
      Html.input [
          attribute "type" "text"
        , attribute "value" answer.text
        , attribute "id" (Answer.Field.id answer_field)
        , onInput (UpdateAnswerFieldValue params.text_component answer_field >> params.msg)
        , classList [ ("input_error", Answer.Field.error answer_field) ]
      ] []
    , (edit_answer_feedback params answer_field)
    ]

view_editable_answer : (AnswerFieldParams msg) -> AnswerField -> Html msg
view_editable_answer params answer_field =
  let
    answer = Answer.Field.answer answer_field
  in
    div [
      classList [("answer_item", True)] ] [
        Html.input ([
           attribute "type" "radio"
         , attribute "name" (Answer.Field.name answer_field)
         , onCheck (UpdateAnswerFieldCorrect params.text_component answer_field >> params.msg)
        ] ++ (if answer.correct then [attribute "checked" "checked"] else [])) []
    , (case (Answer.Field.editable answer_field) of
         True -> edit_answer params answer_field
         False -> view_answer params answer_field)
    ]