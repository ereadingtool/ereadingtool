module Text.Field exposing (TextComponent, TextField, emptyTextComponent, add_new_text, body, text, update_errors)

import Array exposing (Array)
import Field
import Dict exposing (Dict)

import Text.Model exposing (Text, TextDifficulty)
import Question.Field exposing (QuestionField, generate_question_field)

type alias TextField = {
    id : String
  , editable : Bool
  , hover : Bool
  , error : Bool
  , index : Int }

type alias TextFields = {
    title: Field.FieldAttributes TextField
  , source: Field.FieldAttributes TextField
  , difficulty: Field.FieldAttributes TextField
  , author: Field.FieldAttributes TextField
  , body: Field.FieldAttributes TextField }

type alias TextComponentAttributes = { index: Int }

type TextComponent = TextComponent Text TextComponentAttributes TextFields (Array QuestionField)

generate_text_field : Int -> String -> TextField
generate_text_field i attr = {
    id=String.join "_" ["text", toString i, attr]
  , editable=False
  , hover=False
  , error=False
  , index=i }

emptyTextComponent : Int -> TextComponent
emptyTextComponent i = TextComponent Text.Model.emptyText { index=i } {
     title=generate_text_field i "title"
  ,  source=generate_text_field i "source"
  ,  difficulty=generate_text_field i "difficulty"
  ,  author=generate_text_field i "author"
  ,  body=generate_text_field i "body"
  } Question.Field.initial_question_fields

add_new_text : Array TextComponent -> Array TextComponent
add_new_text components = let arr_len = Array.length components in Array.push (emptyTextComponent arr_len) components

body : TextComponent -> TextField
body (TextComponent text attr fields question_fields) = fields.body

text : TextComponent -> Text
text (TextComponent text attr fields question_fields) = text

-- maps an error dictionary to a list of text components
update_errors : (Dict String String) -> Array TextComponent -> Array TextComponent
update_errors errors components = components

{-

view_body : TextField -> Html msg
view_body text_field text_field_attribute = Html.div (text_property_attrs text_field) [
    Html.text "Text: "
  , Html.text text_field.text.body ]

view_editable_text_field : { editable } -> (Text -> TextField -> Html msg) -> (Text -> TextField -> Html msg) -> Html msg

viewTextComponent : TextComponent -> Html msg
view_text_field (TextComponent text fields question_fields) = div [ classList [("text_properties", True)] ] [
      div [ classList [("text_property_items", True)] ] [
           view_editable fields.title view_title edit_title
      ]
      , div [ classList [("body",True)] ]  [ view_editable fields.body view_body edit_body ]
  ]

edit_body : TextField -> TextFieldAttribute -> Html msg
edit_body text_field text_field_attribute = Html.textarea [
        onInput UpdateBody
      , attribute "id" text_field_attribute.id ] [ Html.text text_field.text.body ]

-}
