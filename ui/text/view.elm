module Text.View exposing (view_text_components)

import Text.Model exposing (TextDifficulty)
import Text.Component.Group exposing (TextComponentGroup)
import Text.Component exposing (TextComponent, TextField)
import Text.Update exposing (..)

import Question.View

import Html exposing (..)
import Html.Attributes exposing (classList, attribute, class)

import Array exposing (Array)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Config exposing (text_char_limit)

-- wraps the text field along with other items for easy passing to view functions
type alias TextField msg = {
    text_component: TextComponent
  , msg: (Text.Update.Msg -> msg)
  , text: Text.Model.Text
  , difficulties: List TextDifficulty
  , field: Text.Component.TextField }

view_editable : (TextField msg)
  -> ((TextField msg) -> Html msg)
  -> ((TextField msg) -> Html msg)
  -> Html msg
view_editable params view edit =
  case (Text.Component.editable params.field) of
    True -> edit params
    _ -> view params

view_body : (TextField msg) -> Html msg
view_body params =
  div [
    attribute "id" (Text.Component.text_field_id params.field)
  , toggle_editable onClick params
  , attribute "class" "text_property"
  ] [ div [attribute "class" "editable"] [ Html.text params.text.body ]]

edit_body : (TextField msg) -> Html msg
edit_body params =
  Html.div [] [
    Html.textarea [
        attribute "id" (Text.Component.text_field_id params.field)
      , onInput (UpdateTextValue params.text_component "body" >> params.msg) ] [
        Html.text params.text.body
    ]
  ]

toggle_editable : (msg -> Attribute msg) -> (TextField msg) -> Attribute msg
toggle_editable event params = event <| params.msg (ToggleEditable params.text_component (Text params.field))

view_text_component : (Msg -> msg) -> List TextDifficulty -> TextComponent -> List (Html msg)
view_text_component msg text_difficulties text_component =
  let
    text = Text.Component.text text_component
    body_field = Text.Component.body text_component
    params field = {text_component=text_component, text=text, msg=msg, difficulties=text_difficulties, field=field}
  in [
  div [attribute "class" "text"] <| [
    -- text attributes
    div [ classList [("text_properties", True)] ] [
        div [ classList [("body",True)] ] [
            div [] [ Html.text "Text Body" ]
          , view_editable (params body_field) view_body edit_body
        ]
    ]
  ] ++ [
      Question.View.view_questions msg text_component (Text.Component.question_fields text_component)
    , Question.View.view_question_buttons msg text_component
    , div [class "cursor", onClick (msg <| DeleteText text_component)] [ Html.text "Delete Text" ] ] ]

view_text_components : (Msg -> msg) -> TextComponentGroup -> List TextDifficulty -> Html msg
view_text_components msg text_components text_difficulties =
    Html.div [attribute "class" "texts"]
    <| List.foldr (++) []
    <| Array.toList
    <| Array.map (view_text_component msg text_difficulties) (Text.Component.Group.toArray text_components)
