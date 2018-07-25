module Text.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (classList, attribute, class)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck)

import Dict exposing (Dict)

import Text.Component exposing (TextComponent)
import Text.Field exposing (TextIntro, TextTitle, TextTags, TextAuthor, TextSource, TextDifficulty)

import Date.Utils

import Instructor.Profile exposing (InstructorProfile)

import Text.Create exposing (..)
import Text.Section.View
import Text.Update

import Text.Tags.View


view_text_date : TextViewParams -> Html Msg
view_text_date params =
  div [attribute "class" "text_dates"] <|
    (case params.text.modified_dt of
      Just modified_dt ->
        case params.text.last_modified_by of
          Just last_modified_by ->
            [ span [] [ Html.text
              ("Last Modified by " ++ last_modified_by ++ " on " ++ Date.Utils.month_day_year_fmt modified_dt) ]]
          _ -> []
      _ -> []) ++
        (case params.text.created_dt of
          Just created_dt ->
            case params.text.created_by of
              Just created_by ->
                [ span [] [ Html.text
                  ("Created by " ++ created_by ++ " on " ++ Date.Utils.month_day_year_fmt created_dt) ] ]
              _ -> []
          _ -> [])

view_text_title : TextViewParams -> (TextViewParams -> TextTitle -> Html Msg) -> TextTitle -> Html Msg
view_text_title params edit_view text_title =
  let
    text_title_attrs = Text.Field.text_title_attrs text_title
  in
    div [ onClick (ToggleEditable (Title text_title) True)
        , attribute "id" text_title_attrs.id
        , classList [("input_error", text_title_attrs.error)]
        ] <| [
          div [] [ Html.text "Text Title" ]
        , (case text_title_attrs.editable of
          False ->
            div [attribute "class" "editable"] <|
              [ Html.text params.text.title ]
          True -> div [] [ edit_view params text_title ])
    ] ++
      (if text_title_attrs.error then
        [ div [class "error"] [ Html.text text_title_attrs.error_string ]]
       else [])

edit_text_title : TextViewParams -> TextTitle -> Html Msg
edit_text_title params text_title =
  let
    text_title_attrs = Text.Field.text_title_attrs text_title
  in
    Html.input [
        attribute "id" text_title_attrs.input_id
      , attribute "type" "text"
      , attribute "value" params.text.title
      , onInput (UpdateTextAttributes "title")
      , (onBlur (ToggleEditable (Title text_title) False)) ] [ ]

view_text_introduction : TextViewParams -> (TextViewParams -> TextIntro -> Html Msg) -> TextIntro -> Html Msg
view_text_introduction params edit_view text_intro =
  let
    text_intro_attrs = Text.Field.text_intro_attrs text_intro
  in
    div [
          attribute "id" text_intro_attrs.id
        , onClick (ToggleEditable (Intro text_intro) True)
        , classList [("input_error", text_intro_attrs.error)]] <| [
      div [] [ Html.text "Text Introduction" ]
    , (case text_intro_attrs.editable of
        True ->
          edit_view params text_intro
        False ->
          div [attribute "id" text_intro_attrs.input_id, attribute "class" "editable"] <|
            [ Html.text params.text.introduction ] ++ (if text_intro_attrs.error then [] else []))
    ] ++
      (if text_intro_attrs.error then
        [ div [class "error"] [ Html.text text_intro_attrs.error_string ]]
       else [])

edit_text_introduction : TextViewParams -> TextIntro -> Html Msg
edit_text_introduction params text_intro =
  let
    text_intro_attrs = Text.Field.text_intro_attrs text_intro
  in
    div [] [
      textarea [
        attribute "id" text_intro_attrs.input_id
      , classList [("text_introduction", True), ("input_error", text_intro_attrs.error)]
      , onInput (UpdateTextAttributes "introduction") ] [ Html.text params.text.introduction ]
    ]

view_edit_text_tags : TextViewParams -> TextTags -> Html Msg
view_edit_text_tags params text_tags =
  let
    tags = Text.Component.tags params.text_component
    tag_list = Dict.keys params.tags
  in
    Text.Tags.View.view_tags "add_tag" tag_list tags (onInput (AddTagInput "add_tag"), DeleteTag)

view_edit_text_lock : TextViewParams -> Html Msg
view_edit_text_lock params =
  let
    write_locked = params.write_locked
  in
    div [attribute "id" "text_lock"] [
          div [] [Html.text <| (if write_locked then "Text Locked" else "Text Unlocked")]
        , div [attribute "id" "lock_box", classList [("dimgray_bg", write_locked)], onClick ToggleLock] [
            div [attribute "id" (if write_locked then "lock_right" else "lock_left")] []
          ]
    ]

view_text_lock : TextViewParams -> Html Msg
view_text_lock params =
  case params.mode of
    EditMode -> view_edit_text_lock params
    ReadOnlyMode write_locker ->
      case write_locker == Instructor.Profile.username params.profile of
        True -> view_edit_text_lock params
        _ -> div [] []
    _ -> div [] []

view_author : TextViewParams -> (TextViewParams -> TextAuthor -> Html Msg) -> TextAuthor -> Html Msg
view_author params edit_author text_author =
  let
    text_author_attrs = Text.Field.text_author_attrs text_author
  in
    div [attribute "id" "text_author_view", attribute "class" "text_property"] <| [
      div [] [ Html.text "Text Author" ]
    , (case text_author_attrs.editable of
       False ->
          div [
            attribute "id" text_author_attrs.id
          , attribute "class" "editable"
          , onClick (ToggleEditable (Author text_author) True)
          ] [
            div [] [ Html.text params.text.author ]
          ]
       True -> div [] [ edit_author params text_author ])
    ] ++
      (if text_author_attrs.error then
        [ div [class "error"] [ Html.text text_author_attrs.error_string ]]
       else [])

edit_author : TextViewParams -> TextAuthor -> Html Msg
edit_author params text_author =
  let
    text_author_attrs = Text.Field.text_author_attrs text_author
  in
    Html.input [
      attribute "type" "text"
    , attribute "value" params.text.author
    , attribute "id" text_author_attrs.input_id
    , classList [("input_error", text_author_attrs.error)]
    , onInput (UpdateTextAttributes "author")
    , onBlur (ToggleEditable (Author text_author) False) ] [ Html.text params.text.author ]

edit_difficulty : TextViewParams -> TextDifficulty -> Html Msg
edit_difficulty params text_difficulty =
  div [attribute "class" "text_property"] [
      div [] [ Html.text "Text Difficulty" ]
    , Html.select [
         onInput (UpdateTextAttributes "difficulty") ] [
        Html.optgroup [] (List.map (\(k,v) ->
          Html.option ([attribute "value" k] ++ (if k == params.text.difficulty then [attribute "selected" ""] else []))
           [ Html.text v ]) params.text_difficulties)
       ]
  ]

view_source : TextViewParams -> (TextViewParams -> TextSource -> Html Msg) -> TextSource -> Html Msg
view_source params edit_view text_source =
  let
    text_source_attrs = Text.Field.text_source_attrs text_source
  in
    case text_source_attrs.editable of
      False ->
         div [
          onClick (ToggleEditable (Source text_source) True)
        , classList [("text_property", True), ("input_error", text_source_attrs.error)] ] <| [
          div [attribute "id" text_source_attrs.id] [ Html.text "Text Source" ]
        , div [attribute "class" "editable"] [ Html.text params.text.source ]
       ] ++
         (if text_source_attrs.error then
          [ div [class "error"] [ Html.text text_source_attrs.error_string ]]
          else [])
      True -> edit_view params text_source

edit_source : TextViewParams -> TextSource -> Html Msg
edit_source params text_source =
  let
    text_source_attrs = Text.Field.text_source_attrs text_source
  in
    div [
      classList [("text_property", True)]
    ] [
      div [] [ Html.text "Text Source" ]
    , Html.input [
          attribute "id" (text_source_attrs.input_id)
        , attribute "type" "text"
        , attribute "value" params.text.source
        , onInput (UpdateTextAttributes "source")
        , (onBlur (ToggleEditable (Source text_source) False)) ] [ ]
    ]

view_text_attributes : TextViewParams -> Html Msg
view_text_attributes params =
  div [attribute "id" "text_attributes"] [
     view_text_title params edit_text_title (Text.Field.title params.text_fields)
   , view_text_introduction params edit_text_introduction (Text.Field.intro params.text_fields)
   , view_author params edit_author (Text.Field.author params.text_fields)
   , edit_difficulty params (Text.Field.difficulty params.text_fields)
   , view_source params edit_source (Text.Field.source params.text_fields)
   , view_text_lock params
   , view_text_date params
   , div [classList [("text_property", True)]] [
       div [] [ Html.text "Text Tags" ]
     , view_edit_text_tags params (Text.Field.tags params.text_fields)
     ]
  ]

view_submit : Html Msg
view_submit =
  div [classList [("submit_section", True)]] [
    div [attribute "class" "submit", onClick (TextComponentMsg Text.Update.AddTextSection)] [
        Html.img [
          attribute "src" "/static/img/add_text_section.svg"
        , attribute "height" "20px"
        , attribute "width" "20px"] [], Html.text "Add Text Section"
    ]
  , div [attribute "class" "submit", onClick DeleteText] [
         Html.text "Delete Text", Html.img [
          attribute "src" "/static/img/delete.svg"
        , attribute "height" "18px"
        , attribute "width" "18px"] []
    ]
  , div [] []
  , div [attribute "class" "submit", onClick SubmitText] [
        Html.img [
          attribute "src" "/static/img/save_disk.svg"
        , attribute "height" "20px"
        , attribute "width" "20px"] [], Html.text "Save Text"
    ]
  ]

view_text : TextViewParams -> Html Msg
view_text params =
  div [attribute "id" "text"] <| [
    (view_text_attributes params)
  , (Text.Section.View.view_text_section_components TextComponentMsg (Text.Component.text_section_components params.text_component)
    params.text_difficulties)
  ] ++ (case params.mode of
            ReadOnlyMode write_locker -> []
            _ -> [view_submit])