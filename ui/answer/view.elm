module Answer.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Question.Model
import Answer.Field exposing (AnswerField)

import Text.Update exposing (..)
import Text.Component exposing (TextComponent)

import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

type alias AnswerFieldParams msg = {
    text_component: TextComponent
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
   , onMouseOver (params.msg (Hover params.text_component (Answer answer_field) True))
   , onMouseLeave (params.msg (Hover params.text_component (Answer answer_field ) False))
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
          , onInput (UpdateAnswerFieldValue params.text_component answer_field >> params.msg)
          , attribute "placeholder" "Give some feedback."
          , classList [ ("answer_feedback", True), ("input_error", feedback_field.error) ]
        ] [Html.text answer.feedback]
    ]

edit_answer : (AnswerFieldParams msg) -> AnswerField -> Html msg
edit_answer params answer_field =
  let
    answer = Answer.Field.answer answer_field
    answer_feedback_field_id = String.join "_" [Answer.Field.id answer_field, "feedback"]
  in Html.span [] [
    Html.input [
        attribute "type" "text"
      , attribute "value" answer.text
      , attribute "id" answer_feedback_field_id
      , onInput (UpdateAnswerFieldValue params.text_component answer_field >> params.msg)
      , classList [ ("input_error", Answer.Field.error answer_field) ]
    ] []
  , (edit_answer_feedback params answer_field)
  ]

view_editable_answer : (AnswerFieldParams msg) -> AnswerField -> Html msg
view_editable_answer params answer_field = div [
    classList [("answer_item", True)
              ,("over", Answer.Field.hover answer_field)] ] [
          Html.input [
              attribute "type" "radio"
            , attribute "name" (String.join "_" [
                  "question"
                , toString params.question.order, "correct_answer"])
            , onCheck (UpdateAnswerFieldCorrect params.text_component answer_field >> params.msg)
          ] []
       ,  (case (Answer.Field.editable answer_field) of
             True -> edit_answer params answer_field
             False -> view_answer params answer_field)
    ]
