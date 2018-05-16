module Text.View exposing (view_text_components)

import Text.Model exposing (TextDifficulty)
import Text.Component.Group exposing (TextComponentGroup)
import Text.Component exposing (TextComponent, TextField)
import Text.Update exposing (..)

import Question.View

import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Array exposing (Array)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

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
  case params.field.editable of
    True -> edit params
    _ -> view params

view_author : (TextField msg) -> Html msg
view_author params = Html.div [
    toggle_editable onClick params
  , classList [("text_property", True), ("editable", True)] ] [
      Html.text "Author: "
    , Html.text params.text.author ]

edit_author : (TextField msg) -> Html msg
edit_author params = Html.input [
        attribute "type" "text"
      , attribute "value" params.text.author
      , attribute "id" params.field.id
      , onInput (UpdateTextValue params.text_component "author" >> params.msg)
      , toggle_editable onBlur params ] [ ]

view_source : (TextField msg) -> Html msg
view_source params = Html.div [
   toggle_editable onClick params
 , attribute "class" "text_property"
 , attribute "class" "editable"] [
     Html.text "Source: "
   , Html.text params.text.source
  ]

edit_source : (TextField msg) -> Html msg
edit_source params = Html.input [
        attribute "type" "text"
      , attribute "value" params.text.source
      , attribute "id" params.field.id
      , onInput (UpdateTextValue params.text_component "source" >> params.msg)
      , toggle_editable onBlur params ] [ ]

view_body : (TextField msg) -> Html msg
view_body params =
  Html.div [toggle_editable onClick params, attribute "class" "text_property", attribute "class" "editable"] [
      Html.text "Body: "
    , Html.text params.text.body ]

edit_difficulty : (TextField msg) -> Html msg
edit_difficulty params = Html.div [attribute "class" "text_property"] [
      Html.text "Difficulty:  "
    , Html.select [
         onInput (UpdateTextValue params.text_component "difficulty" >> params.msg) ] [
        Html.optgroup [] (List.map (\(k,v) ->
          Html.option ([attribute "value" k] ++ (if v == params.text.difficulty then [attribute "selected" ""] else []))
           [ Html.text v ]) params.difficulties)
       ]
  ]

edit_body : (TextField msg) -> Html msg
edit_body params = Html.textarea [
      onInput (UpdateTextValue params.text_component "body" >> params.msg)
    , attribute "id" params.field.id ] [ Html.text params.text.body ]


toggle_editable : (msg -> Attribute msg) -> (TextField msg) -> Attribute msg
toggle_editable event params = event <| params.msg (ToggleEditable params.text_component (Text params.field))

view_title : (TextField msg) -> Html msg
view_title params = Html.div [
    toggle_editable onClick params
  , attribute "class" "text_property"
  , attribute "class" "editable"] [
      Html.text "Title: "
    , Html.text params.text.title
    ]

edit_title : (TextField msg) -> Html msg
edit_title params = Html.input [
        attribute "type" "text"
      , attribute "value" params.text.title
      , attribute "id" params.field.id
      , onInput (UpdateTextValue params.text_component "title" >> params.msg)
      , (toggle_editable onBlur params) ] [ ]


view_text_component : (Msg -> msg) -> List TextDifficulty -> TextComponent -> List (Html msg)
view_text_component msg text_difficulties text_component = let
    text = Text.Component.text text_component

    body_field = Text.Component.body text_component
    title_field = Text.Component.title text_component
    source_field = Text.Component.source text_component
    author_field = Text.Component.author text_component
    difficulty_field = Text.Component.difficulty text_component

    params field = {text_component=text_component, text=text, msg=msg, difficulties=text_difficulties, field=field}
  in [
  div [attribute "class" "text"] <| [
    -- text attributes
    div [ classList [("text_properties", True)] ] [
        div [ classList [("text_property_items", True)] ] [
           view_editable (params title_field) view_title edit_title
         , view_editable (params source_field) view_source edit_source
         , view_editable (params difficulty_field) edit_difficulty edit_difficulty
         , view_editable (params author_field) view_author edit_author
        ]
        , div [ classList [("body",True)] ]  [
          view_editable (params body_field) view_body edit_body
        ]
    ]
  ] ++ [ Question.View.view_questions msg text_component (Text.Component.question_fields text_component) ] ]

view_text_components : (Msg -> msg) -> TextComponentGroup -> List TextDifficulty -> Html msg
view_text_components msg text_components text_difficulties =
    Html.div [attribute "class" "texts"]
    <| List.foldr (++) []
    <| Array.toList
    <| Array.map (view_text_component msg text_difficulties) (Text.Component.Group.toArray text_components)
