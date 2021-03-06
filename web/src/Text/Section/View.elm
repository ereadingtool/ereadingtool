module Text.Section.View exposing (view_text_section_components)

import Array
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList)
import Html.Events exposing (onClick, onInput)
import Question.View
import Text.Model exposing (TextDifficulty)
import Text.Section.Component exposing (TextSectionComponent)
import Text.Section.Component.Group exposing (TextSectionComponentGroup)
import Text.Section.Model
import Text.Update exposing (..)



-- wraps the text field along with other items for easy passing to view functions


type alias TextField msg =
    { text_section_component : TextSectionComponent
    , msg : Text.Update.Msg -> msg
    , text_section : Text.Section.Model.TextSection
    , difficulties : List TextDifficulty
    , field : Text.Section.Component.TextSectionField
    }


view_editable :
    TextField msg
    -> (TextField msg -> Html msg)
    -> (TextField msg -> Html msg)
    -> Html msg
view_editable params view edit =
    if Text.Section.Component.editable params.field then
        edit params

    else
        view params


view_body : TextField msg -> Html msg
view_body params =
    div
        [ attribute "id" params.field.id
        , toggle_editable onClick params
        , classList [ ( "input_error", params.field.error ) ]
        , attribute "class" "text_property"
        ]
    <|
        div [ attribute "class" "editable" ] [ Html.text params.text_section.body ]
            :: (if params.field.error then
                    [ div [ class "error" ] [ Html.text params.field.error_string ] ]

                else
                    []
               )


edit_body : TextField msg -> Html msg
edit_body params =
    div []
        [ Html.textarea
            [ attribute "id" params.field.id
            , onInput (UpdateTextValue params.text_section_component "body" >> params.msg)
            ]
            [ Html.text params.text_section.body
            ]
        ]


toggle_editable : (msg -> Attribute msg) -> TextField msg -> Attribute msg
toggle_editable event params =
    event <| params.msg (ToggleEditable params.text_section_component (Text params.field))


view_text_section_component : (Msg -> msg) -> List TextDifficulty -> Int -> TextSectionComponent -> List (Html msg)
view_text_section_component msg text_difficulties answer_feedback_limit text_section_component =
    let
        text_section =
            Text.Section.Component.text_section text_section_component

        body_field =
            Text.Section.Component.body text_section_component

        params field =
            { text_section_component = text_section_component
            , text_section = text_section
            , msg = msg
            , difficulties = text_difficulties
            , field = field
            }
    in
    [ div [ classList [ ( "text", True ), ( "edit-text-section", True ) ] ] <|
        [ -- text attributes
          div [ classList [ ( "text_properties", True ) ] ]
            [ div [ classList [ ( "body", True ) ] ]
                [ div [] [ Html.text ("Text Section " ++ String.fromInt (text_section.order + 1)) ]
                , view_editable (params body_field) view_body edit_body
                ]
            ]
        , Question.View.view_questions msg
            text_section_component
            (Text.Section.Component.question_fields text_section_component)
            answer_feedback_limit
        , Question.View.view_question_buttons msg text_section_component
        , div [ class "cursor", onClick (msg <| DeleteTextSection text_section_component) ]
            [ Html.img
                [ attribute "src" "/public/img/delete.svg"
                , attribute "height" "18px"
                , attribute "width" "18px"
                ]
                []
            , Html.text " Delete Text Section"
            ]
        ]
    ]


view_text_section_components : (Msg -> msg) -> TextSectionComponentGroup -> Int -> List TextDifficulty -> Html msg
view_text_section_components msg text_components answer_feedback_limit text_difficulties =
    Html.div [ attribute "class" "text_sections" ] <|
        List.foldr (++) [] <|
            Array.toList <|
                Array.map
                    (view_text_section_component msg text_difficulties answer_feedback_limit)
                    (Text.Section.Component.Group.toArray text_components)
