module Text.Definitions.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)

import Dict exposing (Dict)

import Text.Definitions exposing (Word, Translation)

import Text.Create exposing (Msg)
import Text.Model

view_translation : Int -> Translation -> Html Msg
view_translation i translation =
  div [class "translation"] [
    div [] [ Html.text (toString (i+1) ++ ". "), Html.text translation ]
  ]

view_translations : Maybe (List Text.Definitions.Translation) -> Html Msg
view_translations translations =
  case translations of
    Just translations_list ->
      div [class "translations"] (List.indexedMap view_translation translations_list)
    Nothing ->
      div [class "translations"] [Html.text "Undefined"]

view_grammeme : (String, Maybe String) -> Html Msg
view_grammeme (grammeme, grammeme_value) =
  case grammeme_value of
    Just value ->
      div [class "grammeme"] [ Html.text grammeme, Html.text " : ", Html.text value ]

    Nothing ->
      div [class "grammeme"] []

view_grammeme_as_string : (String, Maybe String) -> String
view_grammeme_as_string (grammeme, grammeme_value) =
  case grammeme_value of
    Just value ->
      grammeme ++ ": " ++ value

    _ ->
      ""

view_grammemes : Dict String (Maybe String) -> Html Msg
view_grammemes grammemes =
  div [class "grammemes"] (List.map view_grammeme (Dict.toList grammemes))

view_grammemes_as_string : Dict String (Maybe String) -> String
view_grammemes_as_string grammemes =
  String.join ", " <| List.map view_grammeme_as_string (Dict.toList grammemes)

view_word_definition : (Word, Text.Model.WordValues) -> Html Msg
view_word_definition (word, word_values) =
  div [class "definition"] [
    div [class "word"] [
      div [] [ Html.text word ]
    , div [] [ Html.text <| "(" ++ (view_grammemes_as_string word_values.grammemes) ++ ")" ]
    ]
  , Html.text ""
  , view_translations word_values.translations
  ]

view_definitions : Text.Model.Words -> Html Msg
view_definitions words =
  div [class "definitions"] (List.map view_word_definition (Dict.toList words))
