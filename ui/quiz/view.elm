module Quiz.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (classList, attribute)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck)

import Dict exposing (Dict)

import Quiz.Component exposing (QuizComponent)
import Quiz.Field exposing (QuizIntro, QuizTitle, QuizTags)

import Date.Utils

import Instructor.Profile exposing (InstructorProfile)

import Quiz.Create exposing (..)
import Text.View
import Text.Update


view_quiz_date : QuizViewParams -> Html Msg
view_quiz_date params =
  Html.div [attribute "class" "quiz_dates"] <|
        (case params.quiz.modified_dt of
           Just modified_dt ->
             case params.quiz.last_modified_by of
               Just last_modified_by ->
                 [ span [] [ Html.text
                   ("Last Modified by " ++ last_modified_by ++ " on " ++ Date.Utils.month_day_year_fmt modified_dt) ]]
               _ -> []
           _ -> []) ++
        (case params.quiz.created_dt of
           Just created_dt ->
             case params.quiz.created_by of
               Just created_by ->
                 [ span [] [ Html.text
                   ("Created by " ++ created_by ++ " on " ++ Date.Utils.month_day_year_fmt created_dt) ] ]
               _ -> []
           _ -> [])

view_quiz_title : QuizViewParams -> (QuizViewParams -> QuizTitle -> Html Msg) -> QuizTitle -> Html Msg
view_quiz_title params edit_view quiz_title =
  div [ onClick (ToggleEditable (Title quiz_title) True)
      , attribute "id" "quiz_title_view"
      , classList [("input_error", Quiz.Field.title_error quiz_title)]
      ] [
      div [] [ Html.text "Quiz Title" ]
    , (case (Quiz.Field.title_editable quiz_title) of
      False ->
        div [attribute "class" "editable"] <|
          [ Html.text params.quiz.title ] ++ (if (Quiz.Field.title_error quiz_title) then [] else [])
      True -> div [] [ edit_view params quiz_title ])
  ]

edit_quiz_title : QuizViewParams -> QuizTitle -> Html Msg
edit_quiz_title params quiz_title =
  Html.input [
      attribute "id" (Quiz.Field.title_id quiz_title)
    , attribute "type" "text"
    , attribute "value" params.quiz.title
    , onInput (UpdateQuizAttributes "title")
    , (onBlur (ToggleEditable (Title quiz_title) False)) ] [ ]

view_quiz_introduction : QuizViewParams -> (QuizViewParams -> QuizIntro -> Html Msg) -> QuizIntro -> Html Msg
view_quiz_introduction params edit_view quiz_intro =
  div [
        attribute "id" "quiz_intro_view"
      , onClick (ToggleEditable (Intro quiz_intro) True)
      , classList [("input_error", Quiz.Field.intro_error quiz_intro)]] [
    div [] [ Html.text "Quiz Introduction" ]
  , (case (Quiz.Field.intro_editable quiz_intro) of
      False ->
        div [attribute "class" "editable"] <|
          [ Html.text params.quiz.introduction ] ++ (if (Quiz.Field.intro_error quiz_intro) then [] else [])
      True -> edit_view params quiz_intro)
  ]

edit_quiz_introduction : QuizViewParams -> QuizIntro -> Html Msg
edit_quiz_introduction params quiz_intro =
  div [] [
    textarea [
      attribute "id" (Quiz.Field.intro_id quiz_intro)
    , attribute "class" "quiz_introduction"
    , onInput (UpdateQuizAttributes "introduction") ] [ Html.text params.quiz.introduction ]
  ]

view_edit_quiz_tags : QuizViewParams -> QuizTags -> Html Msg
view_edit_quiz_tags params quiz_tags =
  let
    tags = Quiz.Component.tags params.quiz_component
    view_tag tag = div [attribute "class" "quiz_tag"] [
      Html.img [
          attribute "src" "/static/img/cancel.svg"
        , attribute "height" "13px"
        , attribute "width" "13px"
        , attribute "class" "tag_delete_btn"
        , onClick (DeleteTag tag) ] [], Html.text tag ]
  in
    div [attribute "id" "quiz_tags_view", classList [("input_error", Quiz.Field.tag_error quiz_tags)] ] [
          datalist [attribute "id" "tag_list", attribute "type" "text"] <|
            List.map (\tag -> option [attribute "value" tag] [ Html.text tag ]) (Dict.keys params.tags)
        , div [] [Html.text "Quiz Tags"]
        , div [attribute "class" "quiz_tags"] (List.map view_tag (Dict.keys tags))
        , div [] [ Html.input [
            attribute "id" "add_tag"
          , attribute "placeholder" "add tags.."
          , attribute "list" "tag_list"
          , onInput (AddTagInput "add_tag")] [] ]
    ]

view_edit_quiz_lock : QuizViewParams -> Html Msg
view_edit_quiz_lock params =
  let
    write_locked = params.write_locked
  in
    div [attribute "id" "quiz_lock"] [
          div [] [Html.text <| (if write_locked then "Quiz Locked" else "Quiz Unlocked")]
        , div [attribute "id" "lock_box", classList [("dimgray_bg", write_locked)], onClick ToggleLock] [
            div [attribute "id" (if write_locked then "lock_right" else "lock_left")] []
          ]
    ]

view_quiz_lock : QuizViewParams -> Html Msg
view_quiz_lock params =
  case params.mode of
    EditMode -> view_edit_quiz_lock params
    ReadOnlyMode write_locker ->
      case write_locker == Instructor.Profile.username params.profile of
        True -> view_edit_quiz_lock params
        _ -> div [] []
    _ -> div [] []

view_quiz_attributes : QuizViewParams -> Html Msg
view_quiz_attributes params =
  div [attribute "id" "quiz_attributes"] [
     view_quiz_title params edit_quiz_title (Quiz.Field.title params.quiz_fields)
   , view_quiz_introduction params edit_quiz_introduction (Quiz.Field.intro params.quiz_fields)
   , view_edit_quiz_tags params (Quiz.Field.tags params.quiz_fields)
   , view_quiz_lock params
   , view_quiz_date params
  ]

view_submit : Html Msg
view_submit =
  Html.div [classList [("submit_section", True)]] [
    Html.div [attribute "class" "submit", onClick (TextComponentMsg Text.Update.AddText)] [
        Html.img [
          attribute "src" "/static/img/add_text.svg"
        , attribute "height" "20px"
        , attribute "width" "20px"] [], Html.text "Add Text"
    ]
  , Html.div [attribute "class" "submit", onClick DeleteQuiz] [
         Html.text "Delete Quiz", Html.img [
          attribute "src" "/static/img/delete_quiz.svg"
        , attribute "height" "18px"
        , attribute "width" "18px"] []
    ]
  , Html.div [] []
  , Html.div [attribute "class" "submit", onClick SubmitQuiz] [
        Html.img [
          attribute "src" "/static/img/save_disk.svg"
        , attribute "height" "20px"
        , attribute "width" "20px"] [], Html.text "Save Quiz"
    ]
  ]

view_quiz : QuizViewParams -> Html Msg
view_quiz params =
  div [attribute "id" "quiz"] <| [
    (view_quiz_attributes params)
  , (Text.View.view_text_components TextComponentMsg (Quiz.Component.text_components params.quiz_component)
    params.text_difficulties)
  ] ++ (case params.mode of
            ReadOnlyMode write_locker -> []
            _ -> [view_submit])