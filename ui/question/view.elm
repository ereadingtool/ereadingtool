module Question.View exposing (..)

import Text.Model exposing (Text)
import Text.Field exposing (TextComponent, TextField)
import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Question.Field

import Array exposing (Array)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)


edit_question : QuestionField -> Html msg
edit_question question_field =
  Html.div [classList [("question_item", True)] ] [
    Html.textarea [
      attribute "rows" "2"
    , attribute "cols" "100"
    , attribute "id" question_field.id
    , onInput (UpdateQuestionBody question_field)
    , onBlur (ToggleEditableField <| Question question_field)
    ] [Html.text question_field.question.body] ]

view_question : QuestionField -> Html msg
view_question question_field =
  div [
      attribute "id" question_field.id
    , classList [("question_item", True), ("over", question_field.hover), ("input_error", question_field.error)]
    , onClick (ToggleEditableField <| Question question_field)
    , onMouseOver (Hover <| Question question_field)
    , onMouseLeave (UnHover <| Question question_field)
  ] [
       Html.text (if String.isEmpty question_field.question.body then
         "Click to write the question text." else
         question_field.question.body)
  ]

view_delete_menu_item : QuestionField -> Html msg
view_delete_menu_item field =
    Html.span [onClick (DeleteQuestion field.index)] [ Html.text "Delete" ]

view_question_type_menu_item : QuestionField -> Html msg
view_question_type_menu_item field = let question = field.question in
  Html.div [] [
      (if question.question_type == "main_idea" then
        Html.strong [] [ Html.text "Main Idea" ]
       else
        Html.span [
          onClick (UpdateQuestionField { field | question = { question | question_type = "main_idea" } })
        ] [ Html.text "Main Idea" ])
    , Html.text " | "
    , (if question.question_type == "detail" then
        Html.strong [] [ Html.text "Detail" ]
       else
        Html.span [
          onClick (UpdateQuestionField { field | question = { question | question_type = "detail" } })
        ] [ Html.text "Detail" ])
  ]

view_menu_items : QuestionField -> List (Html msg)
view_menu_items field = List.map (\html -> div [attribute "class" "question_menu_item"] [html]) [
      (view_delete_menu_item field)
    , (view_question_type_menu_item field)
  ]

view_question_menu : QuestionField -> Html msg
view_question_menu field =
    div [ classList [("question_menu", True)] ] [
        Html.div [] [
          Html.img [
              attribute "src" "/static/img/action_arrow.svg"
            , onClick (ToggleQuestionMenu <| field)
          ] []
        ], Html.div [
          classList [("question_menu_overlay", True), ("hidden", field.menu_visible)]
        ] (view_menu_items field)
    ]

view_editable_question : QuestionField -> Html msg
view_editable_question field = div [classList [("question_parts", True)]] [
    div [] [ Html.input [attribute "type" "checkbox"] [] ]
  , div [classList [("question", True)]] <| [
       (case field.editable of
          True -> edit_question field
          _ -> view_question field)
    ] ++ (Array.toList <| Array.map (view_editable_answer field) field.answer_fields)
  , (view_question_menu field)]

view_add_question : Array QuestionField -> Html msg
view_add_question fields = div [classList [("add_question", True)], onClick AddQuestion ] [ Html.text "Add question" ]

view_questions : Array QuestionField -> Html msg
view_questions fields = div [ classList [("question_section", True)] ] <|
        (  Array.toList
        <| Array.map view_editable_question fields
        ) ++ [ (view_add_question fields) ]
