module Text.Definitions.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)

import Dict exposing (Dict)

import Text.Definitions exposing (Word, Meaning)

import Text.Create exposing (Msg)
import Text.Model

view_meaning : Int -> Meaning -> Html Msg
view_meaning i meaning =
  div [class "meaning"] [
    div [] [ Html.text (toString (i+1) ++ ". "), Html.text meaning ]
  ]

view_meanings : Maybe (List Text.Definitions.Meaning) -> Html Msg
view_meanings meanings =
  case meanings of
    Just meanings_list ->
      div [class "meanings"] (List.indexedMap view_meaning meanings_list)
    Nothing ->
      div [class "meanings"] [Html.text "Undefined"]

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
  , view_meanings word_values.meanings
  ]

view_definitions : Text.Model.Words -> Html Msg
view_definitions words =
  div [class "definitions"] (List.map view_word_definition (Dict.toList words))
