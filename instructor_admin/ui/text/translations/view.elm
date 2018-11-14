module Text.Translations.View exposing (..)

import Text.Translations.Msg exposing (..)

import Text.Translations.Model exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)

import Dict exposing (Dict)

import Text.Translations exposing (Word, Translation)

import Text.Model

view_text_word_translation : (Msg -> msg) -> Int -> Text.Model.TextWordTranslation -> Html msg
view_text_word_translation msg i translation =
  div [class "translation"] [
    div [] [
      Html.text (toString (i+1) ++ ". ")
    , span [onClick (msg (MakeCorrectForContext translation))] [
        Html.text translation.text, Html.text ("(" ++ (toString translation.correct_for_context) ++ ")")
      ]
    ]
  ]

sortByCorrectForContext : List Text.Model.TextWordTranslation -> List Text.Model.TextWordTranslation
sortByCorrectForContext translations =
  let
    is_correct_for_context = (\tr -> tr.correct_for_context)
  in
    (List.filter is_correct_for_context translations) ++ (List.filter (is_correct_for_context >> not) translations)


view_text_word_translations : (Msg -> msg) -> Maybe (List Text.Model.TextWordTranslation) -> Html msg
view_text_word_translations msg translations =
  case translations of
    Just translations_list ->
      div [class "word_translations"]
        (List.indexedMap (view_text_word_translation msg) (sortByCorrectForContext translations_list))

    Nothing ->
      div [class "word_translations"] [Html.text "Undefined"]

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

view_word_translation : (Msg -> msg) -> (Word, Text.Model.TextWord) -> Html msg
view_word_translation msg (word, text_word) =
  div [class "translation"] [
    div [class "word"] [
      div [] [ Html.text word ]
    , div [] [ Html.text <| "(" ++ (view_grammemes_as_string text_word.grammemes) ++ ")" ]
    ]
  , Html.text ""
  , view_text_word_translations msg text_word.translations
  ]

view_current_letter : (Msg -> msg) -> Model -> Html msg
view_current_letter msg model =
  div [id "words"]
    (case model.current_letter of
      Just letter ->
        List.map (view_word_translation msg) (Dict.toList <| Maybe.withDefault Dict.empty (Dict.get letter model.words))

      Nothing ->
        [])

view_letter_menu : (Msg -> msg) -> Model -> Html msg
view_letter_menu msg model =
  let
    underlined letter = letter == Maybe.withDefault "" model.current_letter
  in
    div [id "word_menu"]
      (List.map (\letter ->
        span [] [
          span [classList [("cursor", True), ("underline", underlined letter)], onClick (msg (ShowLetter letter))] [
            Html.text (String.toUpper letter)
          ]
        ]) (Dict.keys model.words))

view_translations : (Msg -> msg) -> Model -> Html msg
view_translations msg model =
  div [class "translations"] [
    view_letter_menu msg model
  , view_current_letter msg model
  ]
