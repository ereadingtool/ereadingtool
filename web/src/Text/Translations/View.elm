module Text.Translations.View exposing (..)

import Array
import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Parser as HtmlParser
import OrderedDict
import Set
import Text.Section.Model
import Text.Section.Words.Tag
import Text.Translations exposing (..)
import Text.Translations.Model exposing (..)
import Text.Translations.Msg exposing (..)
import Text.Translations.TextWord exposing (TextWord)
import Text.Translations.Word.Instance exposing (WordInstance)



-- import VirtualDom


wordInstanceOnClick : Model -> (Msg -> msg) -> WordInstance -> Html.Attribute msg
wordInstanceOnClick model parentMsg wordInstance =
    if Text.Translations.Model.isMergingWords model then
        -- subsequent clicks on word instances will add them to the list of words to be merged
        if Text.Translations.Model.mergingWord model wordInstance then
            onClick (parentMsg (RemoveFromMergeWords wordInstance))

        else
            onClick (parentMsg (AddToMergeWords wordInstance))

    else
        onClick (parentMsg (EditWord wordInstance))


tagWord : Model -> (Msg -> msg) -> Int -> Int -> String -> Html msg
tagWord model parentMsg sectionNumber instance originalToken =
    let
        id =
            String.join "-" [ "section", String.fromInt sectionNumber, "instance", String.fromInt instance, originalToken ]

        token =
            String.toLower originalToken
    in
    if token == " " then
        -- VirtualDom.text token
        Html.div [] []

    else
        let
            wordInstance =
                Text.Translations.Model.newWordInstance
                    model
                    (SectionNumber sectionNumber)
                    instance
                    token

            editingWord =
                Text.Translations.Model.editingWord model token

            mergingWord =
                Text.Translations.Model.mergingWord model wordInstance
        in
        Html.node "span"
            [ Html.Attributes.id id
            , classList [ ( "defined_word", True ), ( "cursor", True ) ]
            ]
            [ span
                [ classList
                    [ ( "edit-highlight", editingWord )
                    , ( "merge-highlight", mergingWord && not editingWord )
                    ]
                , wordInstanceOnClick model parentMsg wordInstance
                ]
                -- [ VirtualDom.text originalToken
                [ Html.div [] []
                ]
            , view_edit model parentMsg wordInstance
            ]


tagSection : Model -> (Msg -> msg) -> Text.Section.Model.TextSection -> Html msg
tagSection model msg section =
    let
        sectionNumber =
            SectionNumber section.order
    in
    div [ id ("section-" ++ String.fromInt section.order), class "section" ]
        -- (Text.Section.Words.Tag.tagWordsAndToVDOM
        --     (tagWord model msg section.order)
        --     (isPartOfCompoundWord model sectionNumber)
        --     (HtmlParser.parse section.body)
        -- )
        []


view_edit : Model -> (Msg -> msg) -> WordInstance -> Html msg
view_edit model parentMsg wordInstance =
    let
        editingWord =
            Text.Translations.Model.editingWordInstance model wordInstance
    in
    div
        [ class "edit_overlay"
        , classList [ ( "hidden", not editingWord ) ]
        ]
        [ div [ class "edit_menu" ] <|
            [ view_overlay_close_btn parentMsg wordInstance
            , view_word_instance model parentMsg wordInstance
            , view_btns model parentMsg wordInstance
            ]
        ]


view_btns : Model -> (Msg -> msg) -> WordInstance -> Html msg
view_btns model parentMsg wordInstance =
    let
        word =
            Text.Translations.Word.Instance.word wordInstance

        sectionNumber =
            Text.Translations.Word.Instance.sectionNumber wordInstance

        normalizedWord =
            String.toLower word

        instanceCount =
            Text.Translations.Model.instanceCount model sectionNumber normalizedWord
    in
    div [ class "text_word_options" ] <|
        [ view_make_compound_text_word model parentMsg wordInstance
        , view_delete_text_word parentMsg wordInstance
        ]
            ++ (if instanceCount > 1 then
                    [ view_match_translations parentMsg wordInstance ]

                else
                    []
               )


view_make_compound_text_word_on_click : Model -> (Msg -> msg) -> WordInstance -> Html.Attribute msg
view_make_compound_text_word_on_click model parentMsg wordInstance =
    case Text.Translations.Model.mergeState model wordInstance of
        Just mergeState ->
            case mergeState of
                Cancelable ->
                    onClick (parentMsg (RemoveFromMergeWords wordInstance))

                Mergeable ->
                    onClick (parentMsg (MergeWords (Text.Translations.Model.mergingWordInstances model)))

        Nothing ->
            onClick (parentMsg (AddToMergeWords wordInstance))


view_make_compound_text_word : Model -> (Msg -> msg) -> WordInstance -> Html msg
view_make_compound_text_word model parentMsg wordInstance =
    let
        mergeState =
            Text.Translations.Model.mergeState model wordInstance

        mergeTxt =
            case mergeState of
                Just state ->
                    case state of
                        Mergeable ->
                            "Merge together"

                        Cancelable ->
                            "Cancel merge"

                Nothing ->
                    "Merge"
    in
    div [ class "text-word-option" ]
        (case Text.Translations.Word.Instance.textWord wordInstance of
            Just _ ->
                [ div
                    [ attribute "title" "Merge into compound word."
                    , classList [ ( "merge-highlight", Text.Translations.Model.mergingWord model wordInstance ) ]
                    , view_make_compound_text_word_on_click model parentMsg wordInstance
                    ]
                    [ Html.text mergeTxt
                    ]
                ]

            Nothing ->
                []
        )


view_delete_text_word : (Msg -> msg) -> WordInstance -> Html msg
view_delete_text_word parentMsg wordInstance =
    let
        textWord =
            Text.Translations.Word.Instance.textWord
    in
    div [ class "text-word-option" ]
        (case textWord wordInstance of
            -- Just textWord ->
            Just word ->
                [ div
                    [ attribute "title" "Delete this word instance from glossing."
                    , onClick (parentMsg (DeleteTextWord word))
                    ]
                    [ Html.text "Delete"
                    ]
                ]

            Nothing ->
                []
        )


view_correct_for_context : Bool -> List (Html msg)
view_correct_for_context correct =
    if correct then
        [ div [ class "correct_checkmark", attribute "title" "Correct for the context." ]
            [ Html.img
                [ attribute "src" "/static/img/circle_check.svg"
                , attribute "height" "12px"
                , attribute "width" "12px"
                ]
                []
            ]
        ]

    else
        []


view_add_as_text_word : (Msg -> msg) -> WordInstance -> Html msg
view_add_as_text_word msg wordInstance =
    div [ class "add_as_text_word" ]
        [ div []
            [ Html.text "Add as text word."
            ]
        , div []
            [ Html.img
                [ attribute "src" "/static/img/add.svg"
                , attribute "height" "17px"
                , attribute "width" "17px"
                , attribute "title" "Add a new translation."
                , onClick (msg (AddTextWord wordInstance))
                ]
                []
            ]
        ]


view_add_translation : (Msg -> msg) -> TextWord -> Html msg
view_add_translation msg textWord =
    div [ class "add_translation" ]
        [ div []
            [ Html.input
                [ attribute "type" "text"
                , placeholder "Add a translation"
                , onInput (UpdateNewTranslationForTextWord textWord >> msg)
                ]
                []
            ]
        , div []
            [ Html.img
                [ attribute "src" "/static/img/add.svg"
                , attribute "height" "17px"
                , attribute "width" "17px"
                , attribute "title" "Add a new translation."
                , onClick (msg (SubmitNewTranslationForTextWord textWord))
                ]
                []
            ]
        ]


view_translation_delete : (Msg -> msg) -> TextWord -> Translation -> Html msg
view_translation_delete msg textWord translation =
    div [ class "translation_delete" ]
        [ Html.img
            [ attribute "src" "/static/img/delete.svg"
            , attribute "height" "17px"
            , attribute "width" "17px"
            , attribute "title" "Delete this translation."
            , onClick (msg (DeleteTranslation textWord translation))
            ]
            []
        ]


view_text_word_translation : (Msg -> msg) -> TextWord -> Translation -> Html msg
view_text_word_translation msg textWord translation =
    div [ classList [ ( "translation", True ) ] ]
        [ div
            [ classList [ ( "editable", True ), ( "phrase", True ) ]
            , onClick (msg (MakeCorrectForContext textWord translation))
            ]
            [ Html.text translation.text ]
        , div [ class "icons" ] <|
            view_correct_for_context translation.correct_for_context
                ++ [ view_translation_delete msg textWord translation ]
        ]


view_exit_btn : Html msg
view_exit_btn =
    Html.img
        [ attribute "src" "/static/img/cancel.svg"
        , attribute "height" "13px"
        , attribute "width" "13px"
        , class "cursor"
        ]
        []


view_overlay_close_btn : (Msg -> msg) -> WordInstance -> Html msg
view_overlay_close_btn parentMsg wordInstance =
    div [ class "edit_overlay_close_btn", onClick (parentMsg (CloseEditWord wordInstance)) ]
        [ view_exit_btn
        ]


view_instance_word : Model -> (Msg -> msg) -> WordInstance -> Html msg
view_instance_word model msg wordInstance =
    let
        word =
            Text.Translations.Word.Instance.word

        wordTxt =
            if Text.Translations.Model.mergingWord model wordInstance then
                let
                    mergingWords =
                        List.map (\( k, v ) -> word v) <|
                            OrderedDict.toList <|
                                OrderedDict.remove
                                    (wordInstanceKey wordInstance)
                                    (Text.Translations.Model.mergingWords model)
                in
                String.join " " (word wordInstance :: mergingWords)

            else
                word wordInstance
    in
    div [ class "word" ]
        [ Html.text wordTxt
        , view_grammemes model msg wordInstance
        ]


view_word_instance : Model -> (Msg -> msg) -> WordInstance -> Html msg
view_word_instance model msg wordInstance =
    div [ class "word_instance" ] <|
        [ view_instance_word model msg wordInstance
        ]
            ++ (case Text.Translations.Word.Instance.textWord wordInstance of
                    Just textWord ->
                        case Text.Translations.TextWord.translations textWord of
                            Just translationsList ->
                                [ div [ class "translations" ] <|
                                    List.map (view_text_word_translation msg textWord) translationsList
                                        ++ [ view_add_translation msg textWord ]
                                ]

                            Nothing ->
                                [ view_add_translation msg textWord ]

                    Nothing ->
                        [ view_add_as_text_word msg wordInstance ]
               )


view_match_translations : (Msg -> msg) -> WordInstance -> Html msg
view_match_translations parentMsg wordInstance =
    div [ class "text-word-option" ]
        [ div
            [ attribute "title" "Use these translations across all instances of this word"
            , onClick (parentMsg (MatchTranslations wordInstance))
            ]
            [ Html.text "Save for all"
            ]
        ]


view_grammeme : ( String, String ) -> Html msg
view_grammeme ( grammeme, grammemeValue ) =
    div [ class "grammeme" ] [ Html.text grammeme, Html.text " : ", Html.text grammemeValue ]


view_add_grammemes : Model -> (Msg -> msg) -> WordInstance -> Html msg
view_add_grammemes model msg wordInstance =
    let
        grammemeKeys =
            Set.toList Text.Translations.Word.Instance.grammemeKeys

        grammemeValue =
            Text.Translations.Model.editingGrammemeValue model wordInstance
    in
    div [ class "add" ]
        [ select [ onInput (SelectGrammemeForEditing wordInstance >> msg) ]
            (List.map (\grammeme -> option [ value grammeme ] [ Html.text grammeme ]) grammemeKeys)
        , div [ onInput (InputGrammeme wordInstance >> msg) ]
            [ Html.input [ placeholder "add/edit a grammeme..", value grammemeValue ] []
            ]
        , div []
            [ Html.img
                [ attribute "src" "/static/img/save.svg"
                , attribute "height" "17px"
                , attribute "width" "17px"
                , attribute "title" "Save edited grammemes."
                , onClick (msg (SaveEditedGrammemes wordInstance))
                ]
                []
            ]
        ]


view_grammemes : Model -> (Msg -> msg) -> WordInstance -> Html msg
view_grammemes model msg wordInstance =
    div [ class "grammemes" ] <|
        (case Text.Translations.Word.Instance.grammemes wordInstance of
            Just grammemes ->
                List.map view_grammeme <| Dict.toList grammemes

            Nothing ->
                []
        )
            ++ [ view_add_grammemes model msg wordInstance ]


view_translations : (Msg -> msg) -> Maybe Model -> Html msg
view_translations msg translationModel =
    case translationModel of
        Just model ->
            div [ id "translations_tab" ] (List.map (tagSection model msg) (Array.toList model.text.sections))

        Nothing ->
            div [ id "translations_tab" ]
                [ Html.text "No translations available"
                ]
