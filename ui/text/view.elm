module Text.View exposing (view_text_components)

import Text.Field exposing (TextComponent, TextField)
import Text.Update exposing (Msg)

import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Array exposing (Array)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)



{-
view_title : Text.Model.Text -> Text.Field.TextComponent -> Html msg
view_title model field = Html.div (text_property_attrs field) [
    Html.text "Title: "
  , Html.text model.text.title
  ]

edit_title : Text.Model.Text -> Text.Field.TextComponent -> Html msg
edit_title text_field text_attribute = Html.input [
        attribute "type" "text"
      , attribute "value" text_field.text.title
      , attribute "id" "title"
      , onInput UpdateTitle
      , onBlur (ToggleEditableField <| Text text_field) ] [ ]

view_source : Text.Model.Text -> Text.Field.TextComponent -> Html msg
view_source text_field text_attribute = Html.div (text_property_attrs text_field) [
     Html.text "Source: "
   , Html.text text_field.text.source
  ]

edit_source : Text.Model.Text -> Text.Field.TextComponent -> Html msg
edit_source text_field text_field_attribute = Html.input [
        attribute "type" "text"
      , attribute "value" text_field.text.source
      , attribute "id" "source"
      , onInput UpdateSource
      , onBlur (ToggleEditableField <| Text text_field) ] [ ]

edit_difficulty : Text.Model.Text -> Text.Field.TextComponent -> Html msg
edit_difficulty model text_field text_field_attribute = Html.div [] [
      Html.text "Difficulty:  "
    , Html.select [
         onInput UpdateDifficulty ] [
        Html.optgroup [] (List.map (\(k,v) ->
          Html.option ([attribute "value" k] ++ (if v == text_field.text.difficulty then [attribute "selected" ""] else []))
           [ Html.text v ]) model.question_difficulties)
       ]
  ]


view_author : Text.Model.Text -> Text.Field.TextComponent -> Html msg
view_author text_field text_field_attribute = Html.div (text_property_attrs text_field) [
    Html.text "Author: "
  , Html.text text_field.text.author ]

edit_author : Text.Model.Text -> Text.Field.TextComponent -> Html msg
edit_author text_field text_field_attribute = Html.input [
        attribute "type" "text"
      , attribute "value" text_field.text.author
      , attribute "id" "author"
      , onInput UpdateAuthor
      , onBlur (ToggleEditableField <| Text text_field) ] [ ]
-}

type alias TextField msg = {
    parent: TextComponent
  , msg: (Text.Update.Msg -> msg)
  , attrs: Text.Field.TextField }

view_editable : (TextField msg)
  -> ((TextField msg) -> Html msg)
  -> ((TextField msg) -> Html msg)
  -> Html msg
view_editable text_field view edit =
  case text_field.attrs.editable of
    True -> edit text_field
    _ -> view text_field

html_attrs : List (Html.Attribute msg)
html_attrs = []

view_body : (TextField msg) -> Html msg
view_body text_field = let
    text = Text.Field.text text_field.parent
  in
    Html.div html_attrs [
      Html.text "Text: "
    , Html.text text.body ]

edit_body : (TextField msg) -> Html msg
edit_body text_field = let
    text = Text.Field.text text_field.parent
  in
    Html.textarea [
      onInput (Text.Update.UpdateID text_field.attrs.id >> text_field.msg)
    , attribute "id" text_field.attrs.id ] [ Html.text text.body ]

view_text_component : (Msg -> msg) -> TextComponent -> List (Html msg)
view_text_component msg text_component = let
    body_field = Text.Field.body text_component
  in
  [
  -- text attributes
  div [ classList [("text_properties", True)] ] [
      div [ classList [("text_property_items", True)] ] [
         -- view_editable text fields.title view_title edit_title
         --, view_editable text fields.source view_source edit_source
         --, view_editable text fields.difficulty edit_difficulty edit_difficulty
         --, view_editable text fields.author view_author edit_author
      ]
      , div [ classList [("body",True)] ]  [
        view_editable {parent=text_component, msg=msg, attrs=body_field} view_body edit_body ]
  ]
  -- questions
  -- , [ view_questions question_fields ]
  ]

view_text_components : (Msg -> msg) -> Array TextComponent -> Html msg
view_text_components msg text_components =  Html.span []
  <| List.foldl (++) []
  <| Array.toList
  <| Array.map (view_text_component msg) text_components
