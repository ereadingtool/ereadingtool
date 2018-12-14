module TextReader.View exposing (..)

import Html exposing (Html, div, span)
import Html.Attributes exposing (class, classList, attribute, property)
import Html.Events exposing (onClick, onDoubleClick, onMouseLeave)

import Array exposing (Array)
import Dict exposing (Dict)

import User.Profile exposing (Profile)

import Text.Model
import Text.Translations exposing (Word)

import Text.Translations.View
import Text.Section.Words.Tag

import TextReader.Model exposing (..)

import TextReader.Text.Model exposing (Text)
import TextReader.Section.Model exposing (Section)
import TextReader.Question.Model exposing (TextQuestion)
import TextReader.Answer.Model exposing (TextAnswer)
import TextReader.Msg exposing (Msg(..))

import HtmlParser
import HtmlParser.Util

import VirtualDom


tagWord : Model -> Int -> Section -> Int -> String -> Html Msg
tagWord model i section j word =
  let
    id = String.join "_" [toString i, toString j, word]
    reader_word = TextReaderWord id word
    translations = (TextReader.Section.Model.translations section)
  in
    if (Dict.member word translations) then
      Html.node "span" [classList [("defined_word", True), ("cursor", True)], onClick (Gloss reader_word)] [
        span [classList [("highlighted", TextReader.Model.glossed reader_word model.gloss)] ] [ VirtualDom.text word ]
      , view_gloss translations model reader_word
      ]
    else
      case word == " " of
        True ->
          span [class "space"] []
        False ->
          VirtualDom.text word

view_answer : Section -> TextQuestion -> TextAnswer -> Html Msg
view_answer text_section text_question text_answer =
  let
    question_answered = TextReader.Question.Model.answered text_question

    on_click =
      if question_answered then
        onClick (ViewFeedback text_section text_question text_answer True)
      else
        onClick (Select text_answer)

    answer = TextReader.Answer.Model.answer text_answer

    answer_selected = TextReader.Answer.Model.selected text_answer
    is_correct = TextReader.Answer.Model.correct text_answer
    view_feedback = TextReader.Answer.Model.feedback_viewable text_answer
  in
    div [ classList <| [
            ("answer", True)
          , ("answer_selected", answer_selected)
          ] ++ (if (answer_selected || view_feedback) then
                  if is_correct then
                    [("correct", is_correct)]
                  else
                    [("incorrect", not is_correct)]
                else
                  []
               )
        , on_click] [
      div [classList [("answer_text", True), ("bolder", answer_selected)]] [ Html.text answer.text ]
    , (if (answer_selected || view_feedback) then
        div [class "answer_feedback"] [ Html.em [] [ Html.text answer.feedback ] ] else Html.text "")
    ]

view_question : Section -> TextQuestion -> Html Msg
view_question text_section text_question =
  let
    question = TextReader.Question.Model.question text_question
    answers = TextReader.Question.Model.answers text_question
    text_question_id = String.join "_" ["question", toString question.order]
  in
    div [class "question", attribute "id" text_question_id] [
      div [class "question_body"] [ Html.text question.body ]
    , div [class "answers"]
        (Array.toList <| Array.map (view_answer text_section text_question) answers)
    ]

view_questions : Section -> Html Msg
view_questions section =
  let
    text_reader_questions = TextReader.Section.Model.questions section
  in
    div [class "questions"] (Array.toList <| Array.map (view_question section) text_reader_questions)


view_translation : Text.Translations.Translation -> Html Msg
view_translation translation =
  div [class "translation"] [ Html.text translation ]

view_translations : Maybe (List Text.Translations.Translation) -> Html Msg
view_translations defs =
  div [class "translations"]
    (case defs of
      Just translations ->
        (List.map view_translation translations)

      Nothing ->
        [])

view_word_and_grammemes : TextReaderWord -> Text.Model.WordValues -> Html Msg
view_word_and_grammemes reader_word values =
  div [] [
    Html.text <| reader_word.word ++ " (" ++ Text.Translations.View.view_grammemes_as_string values.grammemes ++ ")"
  ]

view_flashcard_words : Model -> Html Msg
view_flashcard_words model =
  div []
    (List.map (\(normal_form, text_word) -> div [] [ Html.text normal_form ])
    (Dict.toList <| Maybe.withDefault Dict.empty <| User.Profile.flashcards model.profile))

view_flashcard_options : Model -> TextReaderWord -> Html Msg
view_flashcard_options model reader_word =
  let
    flashcards = Maybe.withDefault Dict.empty (User.Profile.flashcards model.profile)
    add = div [class "cursor", onClick (AddToFlashcards reader_word)] [ Html.text "Add to Flashcards" ]
    remove = div [class "cursor", onClick (RemoveFromFlashcards reader_word)] [ Html.text "Remove from Flashcards" ]
  in
    div [class "gloss_flashcard_options"] (if Dict.member reader_word.word flashcards then [remove] else [add])

view_gloss : Text.Model.Words -> Model -> TextReaderWord -> Html Msg
view_gloss dictionary model reader_word =
  let
    word_values = Dict.get reader_word.word dictionary
  in
    case word_values of
      Just values ->
        div [] [
          div [ classList [("gloss_overlay", True), ("gloss_menu", True)]
              , onMouseLeave (UnGloss reader_word)
              , classList [("hidden", not (TextReader.Model.selected reader_word model.gloss))]
              ] [
            view_word_and_grammemes reader_word values
          , view_translations values.translations
          , view_flashcard_options model reader_word
          ]
        ]

      Nothing ->
        div [] []

view_text_section : Model -> Section -> Html Msg
view_text_section model section =
  let
    text_section = TextReader.Section.Model.textSection section
    text_body_vdom = Text.Section.Words.Tag.tagWordsAndToVDOM section (tagWord model)
    section_title = ("Section " ++ (toString (text_section.order +1)) ++ "/" ++ (toString text_section.num_of_sections))
  in
    div [class "text_section"] <| [
        div [class "section_title"] [ Html.text section_title ]
      , div [class "text_body"] text_body_vdom
      , view_questions section
    ]

view_text_introduction : Text -> Html Msg
view_text_introduction text =
  div [attribute "id" "text_intro"] (HtmlParser.Util.toVirtualDom <| HtmlParser.parse text.introduction)

view_text_conclusion : Text -> Html Msg
view_text_conclusion text =
  div [attribute "id" "text_conclusion"]
    (HtmlParser.Util.toVirtualDom <| HtmlParser.parse (Maybe.withDefault "" text.conclusion))

view_prev_btn : Html Msg
view_prev_btn =
  div [onClick PrevSection, class "begin_btn"] [
    Html.text "Previous"
  ]

view_next_btn : Html Msg
view_next_btn =
  div [onClick NextSection, class "begin_btn"] [
    Html.text "Next"
  ]

view_text_complete : Model -> TextScores -> Html Msg
view_text_complete model scores =
  div [class "text"] [
      div [attribute "id" "text_score"] [
        Html.text
          ("Sections complete: " ++ (toString scores.complete_sections) ++ "/" ++ (toString scores.num_of_sections))
      , div [] [
          Html.text
            ("Score: " ++ (toString scores.section_scores) ++ " out of " ++ (toString scores.possible_section_scores))
        ]
      ]
    , view_text_conclusion model.text
    , div [class "nav"] [
        view_prev_btn
      , div [attribute "id" "goback", onClick StartOver] [ Html.text "Start Over" ]
      ]
    ]

view_exceptions : Model -> Html Msg
view_exceptions model =
  div [class "exception"] (case model.exception of
    Just exception ->
      [
        Html.text exception.error_msg
      ]
    Nothing ->
      [])


view_content : Model -> Html Msg
view_content model =
  case model.progress of
    ViewIntro ->
      div [class "text"] <| [
        view_text_introduction model.text
      , div [onClick NextSection, class "nav"] [ div [class "start_btn"] [ Html.text "Start" ] ]
      ]

    ViewSection section ->
      div [class "text"] [
        view_text_section model section
      , view_exceptions model
      , div [class "nav"] [view_prev_btn, view_next_btn]
      ]

    Complete text_scores ->
      view_text_complete model text_scores

    _ ->
      div [] []
