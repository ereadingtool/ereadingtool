module Answer.View exposing (..)

import Text.Model exposing (Text)
import Text.Field exposing (TextComponent, TextField)
import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Question.Field

import Array exposing (Array)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)


update_answer : AnswerField -> Array QuestionField -> Array QuestionField
update_answer answer_field question_fields =
  case Array.get answer_field.question_field_index question_fields of
    Just question_field ->
      let new_question_field = { question_field
      | answer_fields = Array.set answer_field.index answer_field question_field.answer_fields } in
      Array.set new_question_field.index new_question_field question_fields
    _ -> question_fields


view_answer_feedback : QuestionField -> AnswerField -> List (Html msg)
view_answer_feedback question_field answer_field = if not (String.isEmpty answer_field.answer.feedback)
  then
    [ Html.div [classList [("answer_feedback", True), ("grey_bg", True)] ] [ Html.text answer_field.answer.feedback ] ]
  else
    []

view_answer : QuestionField -> AnswerField -> Html msg
view_answer question_field answer_field = Html.span
  [  onClick (ToggleEditableField <| Answer answer_field)
   , onMouseOver (Hover <| Answer answer_field)
   , onMouseLeave (UnHover <| Answer answer_field) ] <|
  [   Html.text answer_field.answer.text ] ++ (view_answer_feedback question_field answer_field)

edit_answer_feedback : QuestionField -> AnswerField -> Html msg
edit_answer_feedback question_field answer_field = Html.div [] [
      Html.textarea [
          attribute "id" answer_field.feedback_field.id
        , attribute "rows" "5"
        , attribute "cols" "75"
        , onBlur (ToggleEditableField <| Answer answer_field)
        , onInput (UpdateAnswerFeedback question_field answer_field)
        , attribute "placeholder" "Give some feedback."
        , classList [ ("answer_feedback", True), ("input_error", answer_field.feedback_field.error) ]
      ] [Html.text answer_field.answer.feedback]
    ]

edit_answer : QuestionField -> AnswerField -> Html msg
edit_answer question_field answer_field =
  let answer_feedback_field_id = String.join "_" [answer_field.id, "feedback"]
   in Html.span [] [
    Html.input [
        attribute "type" "text"
      , attribute "value" answer_field.answer.text
      , attribute "id" answer_field.id
      , onInput (UpdateAnswerText question_field answer_field)
      , classList [ ("input_error", answer_field.error) ]
    ] []
  , (edit_answer_feedback question_field answer_field)
  ]

view_editable_answer : QuestionField -> AnswerField -> Html msg
view_editable_answer question_field answer_field = div [
  classList [("answer_item", True)
            ,("over", answer_field.hover)] ] [
        Html.input [
            attribute "type" "radio"
          , attribute "name" (String.join "_" [
                "question"
              , (toString question_field.question.order), "correct_answer"])
          , onCheck (UpdateAnswerCorrect question_field answer_field)
        ] []
     ,  (case answer_field.editable of
           True -> edit_answer question_field answer_field
           False -> view_answer question_field answer_field)
  ]
