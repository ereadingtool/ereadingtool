module Flashcard.View exposing (..)


import Html exposing (Html, div, span)
import Html.Attributes exposing (id, class, classList, attribute, property)
import Html.Events exposing (onClick, onDoubleClick, onMouseLeave)

import Array exposing (Array)
import Dict exposing (Dict)

import Flashcard.Model exposing (..)
import Flashcard.Msg exposing (Msg(..))


view_content : Model -> Html Msg
view_content model =
  let
    content =
      (case model.session of
        Init ->
          [
            div [id "card"] [Html.text "card"]
          , div [id "controls"] [Html.text "controls"]
          ]

        _ ->
          [])
  in
    div [id "flashcard"] [
      div [id "content"] content
    ]