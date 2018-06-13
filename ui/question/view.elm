module Question.View exposing (..)

import Text.Component exposing (TextComponent, TextField)
import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Question.Model
import Question.Field exposing (QuestionField)
import Answer.View
import Text.Update exposing (..)

import Array exposing (Array)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

type alias QuestionFieldParams msg = {
    text_component: TextComponent
  , question: Question.Model.Question
  , msg: (Text.Update.Msg -> msg) }

toggle_editable : (msg -> Attribute msg) -> (QuestionFieldParams msg) -> QuestionField -> Attribute msg
toggle_editable event params field = event <| params.msg (ToggleEditable params.text_component (Question field))

edit_question : (QuestionFieldParams msg) -> QuestionField -> Html msg
edit_question params field =
  Html.div [classList [("question_item", True)] ] [
    Html.textarea [
      attribute "rows" "2"
    , attribute "cols" "100"
    , attribute "id" (Question.Field.id field)
    , (onInput (params.msg << UpdateQuestionFieldValue params.text_component field))
    , toggle_editable onBlur params field
    ] [Html.text params.question.body] ]

view_question : (QuestionFieldParams msg) -> QuestionField -> Html msg
view_question params question_field =
  div [
      attribute "id" (Question.Field.id question_field)
    , classList [
          ("question_item", True)
        , ("input_error", Question.Field.error question_field)
        , ("editable", True) ]
    , toggle_editable onClick params question_field
  ] [
       Html.text (if String.isEmpty params.question.body then
         "Click to write the question text." else
         params.question.body)
  ]

view_delete_menu_item : (QuestionFieldParams msg) -> QuestionField -> Html msg
view_delete_menu_item params field =
    Html.span [onClick (params.msg ((DeleteQuestion params.text_component field)))] [ Html.text "Delete" ]

view_question_type_menu_item : (QuestionFieldParams msg) -> QuestionField -> Html msg
view_question_type_menu_item params field =
    Html.div [] [
        (if params.question.question_type == "main_idea" then
          Html.strong [] [ Html.text "Main Idea" ]
         else
          Html.span [
            onClick
              (params.msg
                (UpdateQuestionField params.text_component (Question.Field.set_question_type field Question.Field.MainIdea)))
          ] [ Html.text "Main Idea" ])
      , Html.text " | "
      , (if params.question.question_type == "detail" then
          Html.strong [] [ Html.text "Detail" ]
         else
          Html.span [
            onClick
              (params.msg
                (UpdateQuestionField params.text_component (Question.Field.set_question_type field Question.Field.Detail)))
          ] [ Html.text "Detail" ])
    ]

view_menu_items : (QuestionFieldParams msg) -> QuestionField -> List (Html msg)
view_menu_items params field = List.map (\html -> div [attribute "class" "question_menu_item"] [html]) [
      (view_delete_menu_item params field)
    , (view_question_type_menu_item params field)
  ]

view_question_menu : (QuestionFieldParams msg) -> QuestionField -> Html msg
view_question_menu params field =
    div [ classList [("question_menu", True)] ] [
        Html.div [] [
          Html.img [
              attribute "src" "/static/img/action_arrow.svg"
            , (onClick (params.msg (ToggleQuestionMenu params.text_component field)))
          ] []
        ], Html.div [
          classList [("question_menu_overlay", True), ("hidden", not (Question.Field.menu_visible field))]
        ] (view_menu_items params field)
    ]

view_editable_question : (Msg -> msg) -> TextComponent -> QuestionField -> Html msg
view_editable_question msg text_component field = let
    params = {text_component=text_component, question=Question.Field.question field, msg=msg}
  in
    div [classList [("question_parts", True)]] [
      div [] [ Html.input [attribute "type" "checkbox"] [] ]
    , div [classList [("question", True)]] <| [
         (case (Question.Field.editable field) of
            True -> edit_question params field
            _ -> view_question params field)
      ] ++ (Array.toList <| Array.map (Answer.View.view_editable_answer params) (Question.Field.answers field))
    , (view_question_menu params field)]

view_add_question : (Msg -> msg) -> TextComponent -> Html msg
view_add_question msg text_component =
  div [classList [("add_question", True)], (onClick (msg (AddQuestion text_component))) ] [
    Html.text "Add question"
  ]

view_questions : (Msg -> msg) -> TextComponent -> Array QuestionField -> Html msg
view_questions msg text_component fields =
  div [ classList [("question_section", True)] ]
    (  Array.toList
    <| Array.map (view_editable_question msg text_component) fields
    )
