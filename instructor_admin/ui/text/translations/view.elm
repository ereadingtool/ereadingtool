module Text.Translations.View exposing (..)

import Array exposing (Array)

import Text.Translations.Msg exposing (..)
import Text.Translations.Model exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)

import Dict exposing (Dict)

import Text.Section.Words.Tag

import Text.Translations exposing (..)

import Text.Translations.TextWord exposing (TextWord)

import Text.Translations.Word.Instance exposing (WordInstance)

import VirtualDom
import HtmlParser

import Set exposing (Set)


wordInstanceOnClick : Model -> (Msg -> msg) -> WordInstance -> Html.Attribute msg
wordInstanceOnClick model parent_msg word_instance =
  case Text.Translations.Model.isMergingWords model of
    -- subsequent clicks on word instances will add them to the list of words to be merged
    True ->
      case Text.Translations.Model.mergingWord model word_instance of
        True ->
          onClick (parent_msg (RemoveFromMergeWords word_instance))

        False ->
          onClick (parent_msg (AddToMergeWords word_instance))

    False ->
      onClick (parent_msg (EditWord word_instance))

is_part_of_compound_word : Model -> Int -> String -> Maybe (Int, Int, Int)
is_part_of_compound_word model instance word =
  case Text.Translations.Model.getTextWord model instance word of
    Just text_word ->
      case (Text.Translations.TextWord.group text_word) of
        Just group ->
          Just (group.instance, group.pos, group.length)

        Nothing ->
          Nothing

    Nothing ->
      Nothing

tagWord : Model -> (Msg -> msg) -> Int -> String -> Html msg
tagWord model parent_msg instance token =
  let
    id = String.join "_" [toString instance, token]
  in
    case token == " " of
      True ->
        span [class "space"] []

      False ->
        let
          word_instance = Text.Translations.Model.newWordInstance model instance token

          editing_word = Text.Translations.Model.editingWord model token
          merging_word = Text.Translations.Model.mergingWord model word_instance
        in
          Html.node "span" [
            Html.Attributes.id id
          , classList [("defined_word", True), ("cursor", True)]
          ] [
            span [
              classList [
                ("edit-highlight", editing_word)
              , ("merge-highlight", merging_word && (not editing_word))
              ]
            , wordInstanceOnClick model parent_msg word_instance
            ] [
              VirtualDom.text token
            ]
          , view_edit model parent_msg word_instance
          ]

view_edit : Model -> (Msg -> msg) -> WordInstance -> Html msg
view_edit model parent_msg word_instance =
  let
    editing_word = Text.Translations.Model.editingWordInstance model word_instance
  in
    div [ class "edit_overlay"
        , classList [("hidden", not editing_word)]
        ] [
      div [class "edit_menu"] <| [
        view_overlay_close_btn parent_msg word_instance
      , view_word_instance model parent_msg word_instance
      , view_btns model parent_msg word_instance
      ]
    ]

view_btns : Model -> (Msg -> msg) -> WordInstance -> Html msg
view_btns model parent_msg word_instance =
  let
    word = Text.Translations.Word.Instance.word word_instance
    normalized_word = String.toLower word
    instance_count = Text.Translations.Model.instanceCount model normalized_word
  in
    div [class "text_word_options"] <| [
      view_make_compound_text_word model parent_msg word_instance
    , view_delete_text_word parent_msg word_instance
    ] ++ (if instance_count > 1 then [view_match_translations parent_msg word_instance] else [])

view_make_compound_text_word_on_click : Model -> (Msg -> msg) -> WordInstance -> Html.Attribute msg
view_make_compound_text_word_on_click model parent_msg word_instance =
  case (Text.Translations.Model.mergeState model word_instance) of
    Just merge_state ->
      case merge_state of
        Cancelable ->
          onClick (parent_msg (RemoveFromMergeWords word_instance))

        Mergeable ->
          onClick (parent_msg (MergeWords (Text.Translations.Model.mergingWordInstances model)))

    Nothing ->
      onClick (parent_msg (AddToMergeWords word_instance))

view_make_compound_text_word : Model -> (Msg -> msg) -> WordInstance -> Html msg
view_make_compound_text_word model parent_msg word_instance =
  let
    merge_state = Text.Translations.Model.mergeState model word_instance

    merge_txt =
      (case merge_state of
        Just state ->
          case state of
            Mergeable ->
              "Merge together"

            Cancelable ->
              "Cancel merge"

        Nothing ->
          "Merge")
  in
    div [class "text-word-option"]
      (case Text.Translations.Word.Instance.textWord word_instance of
        Just text_word -> [
            div [ attribute "title" "Merge into compound word."
                , classList [("merge-highlight", Text.Translations.Model.mergingWord model word_instance)]
                , view_make_compound_text_word_on_click model parent_msg word_instance] [
                  Html.text merge_txt
                ]
          ]

        Nothing ->
          [])

view_delete_text_word : (Msg -> msg) -> WordInstance -> Html msg
view_delete_text_word parent_msg word_instance =
  let
    textWord = Text.Translations.Word.Instance.textWord
  in
    div [class "text-word-option"]
      (case textWord word_instance of
        Just text_word -> [
          div
            [ attribute "title" "Delete this word instance from glossing."
            , onClick (parent_msg (DeleteTextWord text_word))] [
              Html.text "Delete"
            ]
          ]

        Nothing ->
          [])

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

view_add_as_text_word : (Msg -> msg) -> WordInstance -> Html msg
view_add_as_text_word msg word_instance =
  div [class "add_as_text_word"] [
    div [] [
      Html.text "Add as text word."
    ]
  , div [] [
      Html.img [
        attribute "src" "/static/img/add.svg"
      , attribute "height" "17px"
      , attribute "width" "17px"
      , attribute "title" "Add a new translation."
      , onClick (msg (AddTextWord word_instance))] []
    ]
  ]

view_add_translation : (Msg -> msg) -> TextWord -> Html msg
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
      , onClick (msg (SubmitNewTranslationForTextWord text_word))] []
    ]
  ]

view_translation_delete : (Msg -> msg) -> TextWord -> Translation -> Html msg
view_translation_delete msg text_word translation =
  div [class "translation_delete"] [
      Html.img [
        attribute "src" "/static/img/delete.svg"
      , attribute "height" "17px"
      , attribute "width" "17px"
      , attribute "title" "Delete this translation."
      , onClick (msg (DeleteTranslation text_word translation))] []
    ]

view_text_word_translation : (Msg -> msg) -> TextWord -> Translation -> Html msg
view_text_word_translation msg text_word translation =
  div [classList [("translation", True)]] [
    div [ classList [("editable", True), ("phrase", True)]
        , onClick (msg (MakeCorrectForContext translation))] [ Html.text translation.text ]
  , div [class "icons"] <|
      (view_correct_for_context translation.correct_for_context) ++ [view_translation_delete msg text_word translation]
  ]

view_exit_btn : Html msg
view_exit_btn =
  Html.img [
      attribute "src" "/static/img/cancel.svg"
    , attribute "height" "13px"
    , attribute "width" "13px"
    , class "cursor"
    ] []

view_overlay_close_btn : (Msg -> msg) -> WordInstance -> Html msg
view_overlay_close_btn parent_msg word_instance =
  div [class "edit_overlay_close_btn", onClick (parent_msg (CloseEditWord word_instance))] [
    view_exit_btn
  ]

view_instance_word : Model -> (Msg -> msg) -> WordInstance -> Html msg
view_instance_word model msg word_instance =
  let
    word = Text.Translations.Word.Instance.word
    word_txt =
      (case Text.Translations.Model.mergingWord model word_instance of
        True ->
          let
            word_instance_id = Text.Translations.Word.Instance.id word_instance

            merging_words =
                 List.map (\(k, v) -> word v)
              <| Dict.toList
              <| Dict.remove word_instance_id (Text.Translations.Model.mergingWords model)
          in
            String.join " " ([word word_instance] ++ merging_words)

        False ->
          word word_instance)
  in
    div [class "word"] [
      Html.text word_txt
    , view_grammemes model msg word_instance
    ]

view_word_instance : Model -> (Msg -> msg) -> WordInstance -> Html msg
view_word_instance model msg word_instance =
  div [class "word_instance"] <| [
    view_instance_word model msg word_instance
  ] ++
      (case Text.Translations.Word.Instance.textWord word_instance of
        Just text_word ->
          case Text.Translations.TextWord.translations text_word of
            Just translations_list ->
              [div [class "translations"] <|
                  (List.map (view_text_word_translation msg text_word) translations_list)
               ++ [view_add_translation msg text_word]]

            Nothing ->
              [view_add_translation msg text_word]

        Nothing ->
          [view_add_as_text_word msg word_instance])

view_match_translations : (Msg -> msg) -> WordInstance -> Html msg
view_match_translations parent_msg word_instance =
  div [class "text-word-option"] [
    div [ attribute "title" "Use these translations across all instances of this word"
        , onClick (parent_msg (MatchTranslations word_instance))] [
      Html.text "Save for all"
    ]
  ]

view_grammeme : (String, Maybe String) -> Html msg
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

view_add_grammemes : Model -> (Msg -> msg) -> WordInstance -> Html msg
view_add_grammemes model msg word_instance =
  let
    grammeme_keys = Set.toList Text.Translations.Word.Instance.grammemeKeys
    grammeme_value = Text.Translations.Model.editingGrammemeValue model word_instance
  in
    div [class "add"] [
      select [onInput (SelectGrammemeForEditing word_instance >> msg)]
        (List.map (\grammeme -> option [value grammeme] [ Html.text grammeme ]) grammeme_keys)
    , div [onInput (InputGrammeme word_instance >> msg)] [
        Html.input [placeholder "add/edit a grammeme..", value grammeme_value] []
      ]
    , div [] [
      Html.img [
        attribute "src" "/static/img/add.svg"
      , attribute "height" "17px"
      , attribute "width" "17px"
      , attribute "title" "Save grammeme."
      , onClick (msg (SaveEditedGrammemes word_instance))] []
      ]
    ]

view_grammemes : Model -> (Msg -> msg) -> WordInstance -> Html msg
view_grammemes model msg word_instance =
  div [class "grammemes"] <|
    (case (Text.Translations.Word.Instance.grammemes word_instance) of
       Just gramemmes ->
         [ view_grammeme ("pos", gramemmes.pos)
         , view_grammeme ("tense", gramemmes.tense)
         , view_grammeme ("aspect", gramemmes.aspect)
         , view_grammeme ("form", gramemmes.form)
         , view_grammeme ("mood", gramemmes.mood)
         ]

       Nothing ->
         []) ++ [view_add_grammemes model msg word_instance]

view_grammemes_as_string : Dict String (Maybe String) -> String
view_grammemes_as_string grammemes =
     String.join ", "
  <| List.map (Maybe.withDefault "")
  <| List.filter
       (\str -> case str of
        Just _ -> True
        Nothing -> False)
  <| List.map view_grammeme_as_string (Dict.toList grammemes)

view_translations : (Msg -> msg) -> Maybe Model -> Html msg
view_translations msg translation_model =
  case translation_model of
    Just model ->
      let
        sections = Array.toList model.text.sections
        text_body = String.join " " (List.map (\section -> section.body) sections)

        text_body_vdom =
          Text.Section.Words.Tag.tagWordsAndToVDOM
            (tagWord model msg) (is_part_of_compound_word model) (HtmlParser.parse text_body)
      in
        div [id "translations_tab"] text_body_vdom

    Nothing ->
      div [id "translations_tab"] [
        Html.text "No translations available"
      ]
