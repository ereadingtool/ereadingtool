module Text.View exposing (view_text)

import Dict
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList)
import Html.Events exposing (onBlur, onClick, onInput)
import Text.Component
import Text.Field
    exposing
        ( TextAuthor
        , TextConclusion
        , TextDifficulty
        , TextField(..)
        , TextIntro
        , TextSource
        , TextTags
        , TextTitle
        )
import Text.Section.View
import Text.Tags.View
import Text.Translations.Msg as TranslationsMsg
import Text.Translations.View
import Text.Update
import TextEdit exposing (Mode(..), Tab(..), TextViewParams)
import User.Instructor.Profile as InstructorProfile
import Utils.Date


view_text_date : TextViewParams -> Html msg
view_text_date params =
    div [ attribute "class" "text_dates" ] <|
        (case params.text.modified_dt of
            Just modified_dt ->
                case params.text.last_modified_by of
                    Just last_modified_by ->
                        [ span []
                            [ Html.text
                                ("Last Modified by " ++ last_modified_by ++ " on " ++ Utils.Date.monthDayYearFormat modified_dt)
                            ]
                        ]

                    _ ->
                        []

            _ ->
                []
        )
            ++ (case params.text.created_dt of
                    Just created_dt ->
                        case params.text.created_by of
                            Just created_by ->
                                [ span []
                                    [ Html.text
                                        ("Created by " ++ created_by ++ " on " ++ Utils.Date.monthDayYearFormat created_dt)
                                    ]
                                ]

                            _ ->
                                []

                    _ ->
                        []
               )


view_text_title :
    TextViewParams
    ->
        { onToggleEditable : TextField -> Bool -> msg
        , onUpdateTextAttributes : String -> String -> msg
        }
    ->
        (TextViewParams
         ->
            { onToggleEditable : TextField -> Bool -> msg
            , onUpdateTextAttributes : String -> String -> msg
            }
         -> TextTitle
         -> Html msg
        )
    -> TextTitle
    -> Html msg
view_text_title params messages edit_view text_title =
    let
        text_title_attrs =
            Text.Field.text_title_attrs text_title
    in
    div
        [ onClick (messages.onToggleEditable (Title text_title) True)
        , attribute "id" text_title_attrs.id
        , classList [ ( "input_error", text_title_attrs.error ) ]
        ]
    <|
        [ div [] [ Html.text "Text Title" ]
        , if text_title_attrs.editable then
            div []
                [ edit_view
                    params
                    messages
                    text_title
                ]

          else
            div [ attribute "class" "editable" ] <|
                [ Html.text params.text.title ]
        ]
            ++ (if text_title_attrs.error then
                    [ div [ class "error" ] [ Html.text text_title_attrs.error_string ] ]

                else
                    []
               )


edit_text_title :
    TextViewParams
    ->
        { onToggleEditable : TextField -> Bool -> msg
        , onUpdateTextAttributes : String -> String -> msg
        }
    -> TextTitle
    -> Html msg
edit_text_title params messages text_title =
    let
        text_title_attrs =
            Text.Field.text_title_attrs text_title
    in
    Html.input
        [ attribute "id" text_title_attrs.input_id
        , attribute "type" "text"
        , attribute "value" params.text.title
        , onInput (messages.onUpdateTextAttributes "title")
        , onBlur (messages.onToggleEditable (Title text_title) False)
        ]
        []


view_text_conclusion :
    TextViewParams
    -> (String -> String -> msg)
    -> TextConclusion
    -> Html msg
view_text_conclusion params onUpdateTextAttributes text_conclusion =
    let
        text_conclusion_attrs =
            Text.Field.text_conclusion_attrs text_conclusion
    in
    div
        [ attribute "id" text_conclusion_attrs.id
        , classList [ ( "input_error", text_conclusion_attrs.error ) ]
        ]
    <|
        [ div [] [ Html.text "Text Conclusion" ]
        , div []
            [ textarea
                [ attribute "id" text_conclusion_attrs.input_id
                , classList [ ( "text_conclusion", True ), ( "input_error", text_conclusion_attrs.error ) ]
                , onInput (onUpdateTextAttributes "conclusion")
                ]
                [ Html.text (Maybe.withDefault "" params.text.conclusion) ]
            ]
        ]
            ++ (if text_conclusion_attrs.error then
                    [ div [ class "error" ] [ Html.text text_conclusion_attrs.error_string ] ]

                else
                    []
               )


view_text_introduction :
    TextViewParams
    -> (String -> String -> msg)
    ->
        (TextViewParams
         -> (String -> String -> msg)
         -> TextIntro
         -> Html msg
        )
    -> TextIntro
    -> Html msg
view_text_introduction params onUpdateTextAttributes edit_view text_intro =
    let
        text_intro_attrs =
            Text.Field.text_intro_attrs text_intro
    in
    div
        [ attribute "id" text_intro_attrs.id
        , classList [ ( "input_error", text_intro_attrs.error ) ]
        ]
    <|
        [ div [] [ Html.text "Text Introduction" ]
        , edit_view
            params
            onUpdateTextAttributes
            text_intro
        ]
            ++ (if text_intro_attrs.error then
                    [ div [ class "error" ] [ Html.text text_intro_attrs.error_string ] ]

                else
                    []
               )


edit_text_introduction :
    TextViewParams
    -> (String -> String -> msg)
    -> TextIntro
    -> Html msg
edit_text_introduction params onUpdateTextAttributes text_intro =
    let
        text_intro_attrs =
            Text.Field.text_intro_attrs text_intro
    in
    div []
        [ textarea
            [ attribute "id" text_intro_attrs.input_id
            , classList [ ( "text_introduction", True ), ( "input_error", text_intro_attrs.error ) ]
            , onInput (onUpdateTextAttributes "introduction")
            ]
            [ Html.text params.text.introduction ]
        ]


view_edit_text_tags :
    TextViewParams
    -> (String -> String -> msg)
    -> (String -> msg)
    -> TextTags
    -> Html msg
view_edit_text_tags params onAddTagInput onDeleteTag text_tags =
    let
        tags =
            Text.Component.tags params.text_component

        tag_list =
            Dict.keys params.tags

        tag_attrs =
            Text.Field.text_tags_attrs text_tags
    in
    Text.Tags.View.view_tags "add_tag" tag_list tags ( onInput (onAddTagInput "add_tag"), onDeleteTag ) tag_attrs


view_edit_text_lock :
    TextViewParams
    -> msg
    -> Html msg
view_edit_text_lock params onToggleLock =
    let
        write_locked =
            params.write_locked
    in
    div [ attribute "id" "text_lock" ]
        [ div []
            [ Html.text <|
                if write_locked then
                    "Text Locked"

                else
                    "Text Unlocked"
            ]
        , div
            [ attribute "id" "lock_box"
            , classList
                [ ( "dimgray_bg", write_locked ) ]
            , onClick onToggleLock
            ]
            [ div
                [ attribute "id"
                    (if write_locked then
                        "lock_right"

                     else
                        "lock_left"
                    )
                ]
                []
            ]
        ]


view_text_lock :
    TextViewParams
    -> msg
    -> Html msg
view_text_lock params onToggleLock =
    case params.mode of
        EditMode ->
            view_edit_text_lock params onToggleLock

        ReadOnlyMode write_locker ->
            if write_locker == InstructorProfile.usernameToString (InstructorProfile.username params.profile) then
                view_edit_text_lock params onToggleLock

            else
                div [] []

        _ ->
            div [] []


view_author :
    TextViewParams
    ->
        { onToggleEditable : TextField -> Bool -> msg
        , onUpdateTextAttributes : String -> String -> msg
        }
    ->
        (TextViewParams
         ->
            { onToggleEditable : TextField -> Bool -> msg
            , onUpdateTextAttributes : String -> String -> msg
            }
         -> TextAuthor
         -> Html msg
        )
    -> TextAuthor
    -> Html msg
view_author params messages editAuthor text_author =
    let
        text_author_attrs =
            Text.Field.text_author_attrs text_author
    in
    div [ attribute "id" "text_author_view", attribute "class" "text_property" ] <|
        [ div [] [ Html.text "Text Author" ]
        , if text_author_attrs.editable then
            div [] [ editAuthor params messages text_author ]

          else
            div
                [ attribute "id" text_author_attrs.id
                , attribute "class" "editable"
                , onClick (messages.onToggleEditable (Author text_author) True)
                ]
                [ div [] [ Html.text params.text.author ]
                ]
        ]
            ++ (if text_author_attrs.error then
                    [ div [ class "error" ] [ Html.text text_author_attrs.error_string ] ]

                else
                    []
               )


edit_author :
    TextViewParams
    ->
        { onToggleEditable : TextField -> Bool -> msg
        , onUpdateTextAttributes : String -> String -> msg
        }
    -> TextAuthor
    -> Html msg
edit_author params messages text_author =
    let
        text_author_attrs =
            Text.Field.text_author_attrs text_author
    in
    Html.input
        [ attribute "type" "text"
        , attribute "value" params.text.author
        , attribute "id" text_author_attrs.input_id
        , classList [ ( "input_error", text_author_attrs.error ) ]
        , onInput (messages.onUpdateTextAttributes "author")
        , onBlur (messages.onToggleEditable (Author text_author) False)
        ]
        [ Html.text params.text.author ]


edit_difficulty :
    TextViewParams
    -> (String -> String -> msg)
    -> TextDifficulty
    -> Html msg
edit_difficulty params onUpdateTextAttributes text_difficulty =
    div [ attribute "class" "text_property" ]
        [ div [] [ Html.text "Text Difficulty" ]
        , Html.select
            [ onInput (onUpdateTextAttributes "difficulty")
            ]
            [ Html.optgroup []
                (List.map
                    (\( k, v ) ->
                        Html.option
                            (attribute "value" k
                                :: (if k == params.text.difficulty then
                                        [ attribute "selected" "" ]

                                    else
                                        []
                                   )
                            )
                            [ Html.text v ]
                    )
                    params.text_difficulties
                )
            ]
        ]


view_source :
    TextViewParams
    ->
        { onToggleEditable : TextField -> Bool -> msg
        , onUpdateTextAttributes : String -> String -> msg
        }
    ->
        (TextViewParams
         ->
            { onToggleEditable : TextField -> Bool -> msg
            , onUpdateTextAttributes : String -> String -> msg
            }
         -> TextSource
         -> Html msg
        )
    -> TextSource
    -> Html msg
view_source params messages edit_view text_source =
    let
        text_source_attrs =
            Text.Field.text_source_attrs text_source
    in
    if text_source_attrs.editable then
        edit_view
            params
            { onToggleEditable = messages.onToggleEditable
            , onUpdateTextAttributes = messages.onUpdateTextAttributes
            }
            text_source

    else
        div
            [ onClick (messages.onToggleEditable (Source text_source) True)
            , classList [ ( "text_property", True ), ( "input_error", text_source_attrs.error ) ]
            ]
        <|
            [ div [ attribute "id" text_source_attrs.id ] [ Html.text "Text Source" ]
            , div [ attribute "class" "editable" ] [ Html.text params.text.source ]
            ]
                ++ (if text_source_attrs.error then
                        [ div [ class "error" ] [ Html.text text_source_attrs.error_string ] ]

                    else
                        []
                   )


edit_source :
    TextViewParams
    ->
        { onToggleEditable : TextField -> Bool -> msg
        , onUpdateTextAttributes : String -> String -> msg
        }
    -> TextSource
    -> Html msg
edit_source params messages text_source =
    let
        text_source_attrs =
            Text.Field.text_source_attrs text_source
    in
    div
        [ classList [ ( "text_property", True ) ]
        ]
        [ div [] [ Html.text "Text Source" ]
        , Html.input
            [ attribute "id" text_source_attrs.input_id
            , attribute "type" "text"
            , attribute "value" params.text.source
            , onInput (messages.onUpdateTextAttributes "source")
            , onBlur (messages.onToggleEditable (Source text_source) False)
            ]
            []
        ]


view_text_attributes :
    TextViewParams
    ->
        { onToggleEditable : TextField -> Bool -> msg
        , onUpdateTextAttributes : String -> String -> msg
        , onToggleLock : msg
        , onAddTagInput : String -> String -> msg
        , onDeleteTag : String -> msg
        }
    -> Html msg
view_text_attributes params messages =
    div [ attribute "id" "text_attributes" ]
        [ view_text_title
            params
            { onToggleEditable = messages.onToggleEditable
            , onUpdateTextAttributes = messages.onUpdateTextAttributes
            }
            edit_text_title
            (Text.Field.title params.text_fields)
        , view_text_introduction
            params
            messages.onUpdateTextAttributes
            edit_text_introduction
            (Text.Field.intro params.text_fields)
        , view_author
            params
            { onToggleEditable = messages.onToggleEditable
            , onUpdateTextAttributes = messages.onUpdateTextAttributes
            }
            edit_author
            (Text.Field.author params.text_fields)
        , edit_difficulty
            params
            messages.onUpdateTextAttributes
            (Text.Field.difficulty params.text_fields)
        , view_source params
            { onToggleEditable = messages.onToggleEditable
            , onUpdateTextAttributes = messages.onUpdateTextAttributes
            }
            edit_source
            (Text.Field.source params.text_fields)
        , view_text_lock params messages.onToggleLock
        , view_text_date params
        , view_text_conclusion
            params
            messages.onUpdateTextAttributes
            (Text.Field.conclusion params.text_fields)
        , div [ classList [ ( "text_property", True ) ] ]
            [ div [] [ Html.text "Text Tags" ]
            , view_edit_text_tags
                params
                messages.onAddTagInput
                messages.onDeleteTag
                (Text.Field.tags params.text_fields)
            ]
        ]


view_submit :
    { onTextComponentMsg : Text.Update.Msg -> msg
    , onDeleteText : msg
    , onSubmitText : msg
    }
    -> Html msg
view_submit messages =
    div [ classList [ ( "submit_section", True ) ] ]
        [ div [ attribute "class" "submit", onClick (messages.onTextComponentMsg Text.Update.AddTextSection) ]
            [ Html.img
                [ attribute "src" "/public/img/add_text_section.svg"
                , attribute "height" "20px"
                , attribute "width" "20px"
                ]
                []
            , Html.text "Add Text Section"
            ]
        , div [ attribute "class" "submit", onClick messages.onDeleteText ]
            [ Html.text "Delete Text"
            , Html.img
                [ attribute "src" "/public/img/delete.svg"
                , attribute "height" "18px"
                , attribute "width" "18px"
                ]
                []
            ]
        , div [] []
        , div [ attribute "class" "submit", onClick messages.onSubmitText ]
            [ Html.img
                [ attribute "src" "/public/img/save_disk.svg"
                , attribute "height" "20px"
                , attribute "width" "20px"
                ]
                []
            , Html.text "Save Text"
            ]
        ]


view_tab_menu :
    TextViewParams
    -> (Tab -> msg)
    -> Html msg
view_tab_menu params onToggleTab =
    div [ attribute "id" "tabs_menu" ]
        [ div [ classList [ ( "selected", params.selected_tab == TextTab ) ], onClick (onToggleTab TextTab) ]
            [ Html.text "Text"
            ]
        , div [ classList [ ( "selected", params.selected_tab == TranslationsTab ) ], onClick (onToggleTab TranslationsTab) ]
            [ Html.text "Translations"
            ]
        ]


view_text_tab :
    TextViewParams
    ->
        { onToggleEditable : TextField -> Bool -> msg
        , onTextComponentMsg : Text.Update.Msg -> msg
        , onDeleteText : msg
        , onSubmitText : msg
        , onUpdateTextAttributes : String -> String -> msg
        , onToggleLock : msg
        , onAddTagInput : String -> String -> msg
        , onDeleteTag : String -> msg
        }
    -> Int
    -> Html msg
view_text_tab params messages answer_feedback_limit =
    div [ attribute "id" "text" ] <|
        [ view_text_attributes params
            { onToggleEditable = messages.onToggleEditable
            , onUpdateTextAttributes = messages.onUpdateTextAttributes
            , onToggleLock = messages.onToggleLock
            , onAddTagInput = messages.onAddTagInput
            , onDeleteTag = messages.onDeleteTag
            }
        , Text.Section.View.view_text_section_components messages.onTextComponentMsg
            (Text.Component.text_section_components params.text_component)
            answer_feedback_limit
            params.text_difficulties
        ]
            ++ (case params.mode of
                    ReadOnlyMode write_locker ->
                        []

                    _ ->
                        [ view_submit
                            { onTextComponentMsg = messages.onTextComponentMsg
                            , onDeleteText = messages.onDeleteText
                            , onSubmitText = messages.onSubmitText
                            }
                        ]
               )


view_translations_tab :
    TextViewParams
    -> (TranslationsMsg.Msg -> msg)
    -> Html msg
view_translations_tab params onTextTranslationMsg =
    Text.Translations.View.view_translations
        onTextTranslationMsg
        params.text_translations_model


view_tab_contents :
    TextViewParams
    ->
        { onToggleEditable : TextField -> Bool -> msg
        , onTextComponentMsg : Text.Update.Msg -> msg
        , onDeleteText : msg
        , onSubmitText : msg
        , onUpdateTextAttributes : String -> String -> msg
        , onToggleLock : msg
        , onAddTagInput : String -> String -> msg
        , onDeleteTag : String -> msg
        }
    -> (TranslationsMsg.Msg -> msg)
    -> Int
    -> Html msg
view_tab_contents params messages onTextTranslationMsg answer_feedback_limit =
    case params.selected_tab of
        TextTab ->
            view_text_tab params messages answer_feedback_limit

        TranslationsTab ->
            view_translations_tab params onTextTranslationMsg


view_text :
    TextViewParams
    ->
        { onToggleEditable : TextField -> Bool -> msg
        , onTextComponentMsg : Text.Update.Msg -> msg
        , onDeleteText : msg
        , onSubmitText : msg
        , onUpdateTextAttributes : String -> String -> msg
        , onToggleTab : Tab -> msg
        , onToggleLock : msg
        , onAddTagInput : String -> String -> msg
        , onDeleteTag : String -> msg
        , onTextTranslationMsg : TranslationsMsg.Msg -> msg
        }
    -> Int
    -> Html msg
view_text params messages answer_feedback_limit =
    div [ attribute "id" "tabs" ]
        [ view_tab_menu params messages.onToggleTab
        , div [ attribute "id" "tabs_contents" ]
            [ view_tab_contents params
                { onToggleEditable = messages.onToggleEditable
                , onTextComponentMsg = messages.onTextComponentMsg
                , onDeleteText = messages.onDeleteText
                , onSubmitText = messages.onSubmitText
                , onUpdateTextAttributes = messages.onUpdateTextAttributes
                , onToggleLock = messages.onToggleLock
                , onAddTagInput = messages.onAddTagInput
                , onDeleteTag = messages.onDeleteTag
                }
                messages.onTextTranslationMsg
                answer_feedback_limit
            ]
        ]
