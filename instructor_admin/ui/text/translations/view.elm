module Text.Translations.View exposing (..)

import Text.Translations.Msg exposing (..)

import Text.Translations.Model exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)

import Dict exposing (Dict)

import Text.Translations exposing (Word, Translation)

import Text.Model


view_correct_for_context : Bool -> List (Html msg)
view_correct_for_context correct =
  case correct of
    True ->
      [
        span [class "correct_checkmark", attribute "title" "Correct for the context."] [
          Html.img [
            attribute "src" "/static/img/circle_check.svg"
          , attribute "height" "12px"
          , attribute "width" "12px"] []
        ]
      ]

    False ->
      []

view_add_translation : (Msg -> msg) -> Text.Model.TextWord -> Html msg
view_add_translation msg text_word =
  div [class "add_translation"] [
    div [] [
      Html.input [
        attribute "type" "text"
      , placeholder "Add a translation"
      , onInput (UpdateNewTranslationForTextWord text_word >> msg) ] []
    ]
  , div [] [
      Html.img [
        attribute "src" "/static/img/add.svg"
      , attribute "height" "17px"
      , attribute "width" "17px"
      , attribute "title" "Add a new translation."
      , onClick (msg (AddNewTranslationForTextWord text_word))] []
    ]
  ]

view_translation_delete : (Msg -> msg) -> Text.Model.TextWord -> Text.Model.TextWordTranslation -> Html msg
view_translation_delete msg text_word translation =
  div [] [
      Html.img [
        attribute "src" "/static/img/delete.svg"
      , attribute "height" "17px"
      , attribute "width" "17px"
      , attribute "title" "Delete this translation."
      , onClick (msg (DeleteTranslation text_word translation))] []
    ]

view_text_word_translation : (Msg -> msg) -> Text.Model.TextWord -> Text.Model.TextWordTranslation -> Html msg
view_text_word_translation msg text_word translation =
  div [classList [("translation", True), ("editable", True)], onClick (msg (MakeCorrectForContext translation))] [
    div [] [
      div [] <| [
        Html.text translation.text
      ] ++ (view_correct_for_context translation.correct_for_context)
    ]
  ]

view_text_word_translations : (Msg -> msg) -> Text.Model.TextWord -> Html msg
view_text_word_translations msg text_word =
  case text_word.translations of
    Just translations_list ->
      div [class "word_translations"] <|
        (List.map (view_text_word_translation msg text_word) translations_list) ++
        [view_add_translation msg text_word]

    Nothing ->
      div [class "word_translations"] [Html.text "Undefined"]

view_grammeme : (String, Maybe String) -> Html Msg
view_grammeme (grammeme, grammeme_value) =
  case grammeme_value of
    Just value ->
      div [class "grammeme"] [ Html.text grammeme, Html.text " : ", Html.text value ]

    Nothing ->
      div [class "grammeme"] []

view_grammeme_as_string : (String, Maybe String) -> Maybe String
view_grammeme_as_string (grammeme, grammeme_value) =
  case grammeme_value of
    Just value ->
      Just (grammeme ++ ": " ++ value)

    _ ->
      Nothing

view_grammemes : Dict String (Maybe String) -> Html Msg
view_grammemes grammemes =
  div [class "grammemes"] (List.map view_grammeme (Dict.toList grammemes))

view_grammemes_as_string : Dict String (Maybe String) -> String
view_grammemes_as_string grammemes =
     String.join ", "
  <| List.map
       (\str -> case str of
         Just s -> s
         Nothing -> "")
  <| List.filter
       (\str -> case str of
         Just str -> True
         Nothing -> False)
  <| List.map view_grammeme_as_string (Dict.toList grammemes)

view_word_translation : (Msg -> msg) -> (Word, Text.Model.TextWord) -> Html msg
view_word_translation msg (word, text_word) =
  div [class "translation"] [
    div [class "word"] [
      div [] [ Html.text word ]
    , div [] [ Html.text <| "(" ++ (view_grammemes_as_string text_word.grammemes) ++ ")" ]
    ]
  , Html.text ""
  , view_text_word_translations msg text_word
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
