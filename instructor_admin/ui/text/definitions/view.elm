module Text.Definitions.View exposing (..)

import Html exposing (..)

import Dict exposing (Dict)

import Text.Definitions exposing (Word, Meaning)

import Text.Create exposing (Msg)
import Text.Model

view_meaning : Meaning -> Html Msg
view_meaning meaning =
  div [] [
    div [] [ Html.text (" :" ++ meaning) ]
  ]

view_grammeme : (String, Maybe String) -> Html Msg
view_grammeme (grammeme, grammeme_value) =
  case grammeme_value of
    Just value ->
      div [] [ Html.text grammeme, Html.text " : ", Html.text value ]

    Nothing ->
      div [] []

view_grammemes : Dict String (Maybe String) -> Html Msg
view_grammemes grammemes =
  div [] (List.map view_grammeme (Dict.toList grammemes))

view_word_definition : (Word, Text.Model.WordValues) -> Html Msg
view_word_definition (word, word_values) =
  div [] [
    Html.text word
  , (case word_values.meanings of
      Just meanings_list ->
        div [] (List.map view_meaning meanings_list)
      Nothing ->
        div [] [Html.text "Undefined"]
    )
  , Html.text "Grammemes"
  , view_grammemes word_values.grammemes
  ]

view_definitions : Text.Model.Words -> Html Msg
view_definitions words =
  div [] (List.map view_word_definition (Dict.toList words))
