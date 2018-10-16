module Text.Definitions.View exposing (..)

import Html exposing (..)

import Dict exposing (Dict)

import Text.Definitions exposing (Word, Meaning)

import Text.Create exposing (Msg)


view_meaning : Meaning -> Html Msg
view_meaning meaning =
  div [] [
    div [] [ Html.text (" :" ++ meaning) ]
  ]

view_word_definition : (Word,  Maybe (List Meaning)) -> Html Msg
view_word_definition (word, meanings) =
  div [] [
    Html.text word
  , (case meanings of
      Just meanings_list ->
        div [] (List.map view_meaning meanings_list)
      Nothing ->
        div [] [Html.text "Undefined"]
    )
  ]

view_definitions : Dict Word (Maybe (List Meaning)) -> Html Msg
view_definitions definitions =
  div [] (List.map view_word_definition (Dict.toList definitions))
