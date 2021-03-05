module Answer.View exposing (view_editable_answer)

import Answer.Field exposing (AnswerField)
import Answer.Model
import Html exposing (..)
import Html.Attributes exposing (attribute, classList)
import Html.Events exposing (onBlur, onCheck, onClick, onInput)
import Question.Model
import Text.Section.Component exposing (TextSectionComponent)
import Text.Update exposing (..)


type alias AnswerFieldParams msg =
    { text_section_component : TextSectionComponent
    , answer_feedback_limit : Int
    , question : Question.Model.Question
    , msg : Text.Update.Msg -> msg
    }


view_answer_feedback : AnswerFieldParams msg -> AnswerField -> List (Html msg)
view_answer_feedback params answer_field =
    let
        answer =
            Answer.Field.answer answer_field
    in
    if not (String.isEmpty answer.feedback) then
        [ div [ classList [ ( "answer_feedback", True ), ( "grey_bg", True ) ] ] [ Html.text answer.feedback ] ]

    else
        []


view_answer : AnswerFieldParams msg -> AnswerField -> Html msg
view_answer params answer_field =
    let
        answer =
            Answer.Field.answer answer_field
    in
    span
        [ onClick (params.msg (ToggleEditable params.text_section_component (Answer answer_field)))
        ]
    <|
        [ Html.text
            (case answer.text of
                "" ->
                    Answer.Model.default_answer_text answer

                _ ->
                    answer.text
            )
        ]
            ++ view_answer_feedback params answer_field


edit_answer_feedback : AnswerFieldParams msg -> AnswerField -> Html msg
edit_answer_feedback params answer_field =
    let
        feedback_field =
            Answer.Field.feedback_field answer_field

        answer =
            Answer.Field.answer answer_field
    in
    div []
        [ Html.textarea
            [ attribute "id" feedback_field.id
            , attribute "rows" "5"
            , attribute "cols" "75"
            , onBlur (params.msg (ToggleEditable params.text_section_component (Answer answer_field)))
            , onInput (UpdateAnswerFeedbackValue params.text_section_component answer_field >> params.msg)
            , attribute "placeholder" "Give some feedback."
            , classList [ ( "answer_feedback", True ), ( "input_error", feedback_field.error ) ]
            ]
            [ Html.text answer.feedback ]
        , div
            [ classList
                [ ( "chars_remaining", True )
                , ( "error", (params.answer_feedback_limit - String.length answer.feedback) < 0 )
                ]
            ]
            [ Html.text <|
                "Characters remaining "
                    ++ String.fromInt (params.answer_feedback_limit - String.length answer.feedback)
                    ++ "."
            , Html.text feedback_field.error_string
            ]
        ]


edit_answer : AnswerFieldParams msg -> AnswerField -> Html msg
edit_answer params answer_field =
    let
        answer =
            Answer.Field.answer answer_field
    in
    span []
        [ Html.input
            [ attribute "type" "text"
            , attribute "value" answer.text
            , attribute "id" (Answer.Field.id answer_field)
            , onInput (UpdateAnswerFieldValue params.text_section_component answer_field >> params.msg)
            , classList [ ( "input_error", Answer.Field.error answer_field ) ]
            ]
            []
        , div [ attribute "class" "answer_note" ]
            [ Html.text
                ("Note: A correct answer is required.  To select a correct answer, "
                    ++ "toggle the radio button to choose this answer as the correct answer."
                )
            ]
        , edit_answer_feedback params answer_field
        ]


view_editable_answer : AnswerFieldParams msg -> Int -> AnswerField -> Html msg
view_editable_answer params num_of_answers answer_field =
    let
        answer =
            Answer.Field.answer answer_field

        editing =
            Answer.Field.editable answer_field

        title_text_add =
            "Add new answer after this answer"

        title_text_delete =
            "Delete this answer"
    in
    div [ classList [ ( "answer_item", True ), ( "editable", not editing ) ] ] <|
        [ Html.input
            ([ attribute "type" "radio"
             , attribute "name" (Answer.Field.name answer_field)
             , onCheck (UpdateAnswerFieldCorrect params.text_section_component answer_field >> params.msg)
             ]
                ++ (if answer.correct then
                        [ attribute "checked" "checked" ]

                    else
                        []
                   )
            )
            []
        , if Answer.Field.editable answer_field then
            edit_answer params answer_field

          else
            view_answer params answer_field
        ]
            ++ (case num_of_answers of
                    3 ->
                        [ span
                            [ attribute "class" "answer_add"
                            , onClick (params.msg (AddAnswer params.text_section_component answer_field))
                            ]
                            [ Html.img
                                [ attribute "title" title_text_add
                                , attribute "alt" title_text_add
                                , attribute "src" "/static/img/add.svg"
                                , attribute "height" "18px"
                                , attribute "width" "18px"
                                ]
                                []
                            ]
                        ]

                    4 ->
                        [ span
                            [ attribute "class" "answer_delete"
                            , onClick (params.msg (DeleteAnswer params.text_section_component answer_field))
                            ]
                            [ Html.img
                                [ attribute "title" title_text_delete
                                , attribute "alt" title_text_delete
                                , attribute "src" "/static/img/delete.svg"
                                , attribute "height" "18px"
                                , attribute "width" "18px"
                                ]
                                []
                            ]
                        ]

                    _ ->
                        []
               )
