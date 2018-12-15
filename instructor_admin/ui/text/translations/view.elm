module Text.Translations.View exposing (..)

import Array exposing (Array)

import Text.Translations.Msg exposing (..)
import Text.Translations.Model exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)

import Dict exposing (Dict)

import Text.Section.Words.Tag

import Text.Translations exposing (Word, Translation, TextWord)

import Text.Model
import Text.Section.Model

import VirtualDom
import HtmlParser


tagWord : Model -> (Msg -> msg) -> Int -> Int -> String -> Html msg
tagWord model parent_msg node_index word_index word =
  let
    id = String.join "_" [toString node_index, toString word_index, word]
  in
    case Dict.get word model.words of
      Just text_word ->
        let
          word_instance = {id=id, text_word=text_word}
        in
          Html.node "span" [
            classList [("defined_word", True), ("cursor", True)]
          , onClick (parent_msg (EditWord word_instance))
          ] [
            span [classList [("highlighted", Text.Translations.Model.editingWord model word)]] [ VirtualDom.text word ]
          , view_edit model parent_msg word_instance
          ]

      Nothing ->
        case word == " " of
          True ->
            span [class "space"] []

          False ->
            VirtualDom.text word

view_edit : Model -> (Msg -> msg) -> Text.Model.WordInstance -> Html msg
view_edit model parent_msg word_instance =
  div [] [
    div [ classList [("gloss_overlay", True), ("gloss_menu", True)]
        , classList [("hidden", not (Text.Translations.Model.editingWord model word_instance.text_word.word))]
        ] [
      view_text_word_translations parent_msg word_instance.text_word
    ]
  ]

view_correct_for_context : Bool -> List (Html msg)
view_correct_for_context correct =
  case correct of
    True ->
      [
        div [class "correct_checkmark", attribute "title" "Correct for the context."] [
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
  div [class "translation_delete"] [
      Html.img [
        attribute "src" "/static/img/delete.svg"
      , attribute "height" "17px"
      , attribute "width" "17px"
      , attribute "title" "Delete this translation."
      , onClick (msg (DeleteTranslation text_word translation))] []
    ]

view_text_word_translation : (Msg -> msg) -> Text.Model.TextWord -> Text.Model.TextWordTranslation -> Html msg
view_text_word_translation msg text_word translation =
  div [classList [("translation", True)]] [
    div [ classList [("editable", True), ("phrase", True)]
        , onClick (msg (MakeCorrectForContext translation))] [ Html.text translation.text ]
  , div [class "icons"] <|
      (view_correct_for_context translation.correct_for_context) ++ [view_translation_delete msg text_word translation]
  ]

view_text_word_translations : (Msg -> msg) -> Text.Model.TextWord -> Html msg
view_text_word_translations msg text_word =
  case text_word.translations of
    Just translations_list ->
      div [class "translations"] <|
        (List.map (view_text_word_translation msg text_word) translations_list) ++
        [view_add_translation msg text_word]

    Nothing ->
      div [class "translations"] [Html.text "Undefined"]

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
  <| List.map (Maybe.withDefault "")
  <| List.filter
       (\str -> case str of
        Just _ -> True
        Nothing -> False)
  <| List.map view_grammeme_as_string (Dict.toList grammemes)

view_word_translation : (Msg -> msg) -> (Word, Text.Model.TextWord) -> Html msg
view_word_translation msg (word, text_word) =
  div [class "word"] [
    div [class "word_phrase"] [ Html.text word ]
  , div [class "grammemes"] [ Html.text <| "(" ++ (view_grammemes_as_string text_word.grammemes) ++ ")" ]
  , view_text_word_translations msg text_word
  ]

view_section : (Msg -> msg) -> Model -> Text.Section.Model.TextSection -> Html msg
view_section parent_msg model section =
  let
    text_body_vdom = Text.Section.Words.Tag.tagWordsAndToVDOM (tagWord model parent_msg) (HtmlParser.parse section.body)
  in
    div [class "text_section"] [
      div [class "title"] [
        Html.text ("Section " ++ (toString (section.order+1)))
      ]
    , div [class "body"] [
        div [] text_body_vdom
      ]
    ]

view_translations : (Msg -> msg) -> Maybe Model -> Html msg
view_translations msg translation_model =
  case translation_model of
    Just model ->
      let
        sections = Array.toList model.text.sections
      in
        div [id "translations_tab"] (List.map (view_section msg model) sections)

    Nothing ->
      div [id "translations_tab"] [
        Html.text "No translations available"
      ]
