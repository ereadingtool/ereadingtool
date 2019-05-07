module TextReader.View exposing (..)

import Html exposing (Html, div, span)
import Html.Attributes exposing (id, class, classList, attribute, property)
import Html.Events exposing (onClick, onDoubleClick, onMouseLeave)

import Array exposing (Array)
import Dict exposing (Dict)

import User.Profile.TextReader.Flashcards

import Text.Section.Words.Tag

import TextReader.TextWord
import TextReader.Model exposing (..)

import TextReader.TextWord

import TextReader.Model

import TextReader.Text.Model exposing (Text)
import TextReader.Section.Model exposing (Section, Words)
import TextReader.Question.Model exposing (TextQuestion)
import TextReader.Answer.Model exposing (TextAnswer)
import TextReader.Msg exposing (Msg(..))

import HtmlParser
import HtmlParser.Util

import VirtualDom


tagWord : Model -> Section -> Int -> String -> Html Msg
tagWord model text_reader_section instance token =
  let
    id = String.join "_" [toString instance, token]
    textreader_textword = TextReader.Section.Model.getTextWord text_reader_section instance token
    reader_word = TextReader.Model.new id instance token textreader_textword
  in
    case token == " " of
        True ->
          VirtualDom.text token

        False ->
          case textreader_textword of
            Just text_word ->
              Html.node "span" [
                classList [
                ("defined-word", True)
              , ("cursor", True)]
              , onClick (ToggleGloss reader_word)
              ] [
                span [classList [("highlighted", TextReader.Model.glossed reader_word model.gloss)] ] [
                  VirtualDom.text token
                ]
              , view_gloss model reader_word text_word
              ]

            Nothing ->
              VirtualDom.text token

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
          , ("answer-selected", answer_selected)
          ] ++ (if (answer_selected || view_feedback) then
                  if is_correct then
                    [("correct", is_correct)]
                  else
                    [("incorrect", not is_correct)]
                else
                  []
               )
        , on_click] [
      div [classList [("answer-text", True), ("bolder", answer_selected)]] [ Html.text answer.text ]
    , (if (answer_selected || view_feedback) then
        div [class "answer-feedback"] [ Html.em [] [ Html.text answer.feedback ] ] else Html.text "")
    ]

view_question : Section -> TextQuestion -> Html Msg
view_question text_section text_question =
  let
    question = TextReader.Question.Model.question text_question
    answers = TextReader.Question.Model.answers text_question
    text_question_id = String.join "_" ["question", toString question.order]
  in
    div [class "question", attribute "id" text_question_id] [
      div [class "question-body"] [ Html.text question.body ]
    , div [class "answers"]
        (Array.toList <| Array.map (view_answer text_section text_question) answers)
    ]

view_questions : Section -> Html Msg
view_questions section =
  let
    text_reader_questions = TextReader.Section.Model.questions section
  in
    div [id "questions"] (Array.toList <| Array.map (view_question section) text_reader_questions)


view_translation : TextReader.TextWord.Translation -> Html Msg
view_translation translation =
  div [class "translation"] [ Html.text translation.text ]

view_translations : Maybe (List TextReader.TextWord.Translation) -> Html Msg
view_translations defs =
  div [class "translations"]
    (case defs of
      Just translations ->
        (List.map view_translation (List.filter (\tr -> tr.correct_for_context) translations))

      Nothing ->
        [])

view_word_and_grammemes : TextReaderWord -> TextReader.TextWord.TextWord -> Html Msg
view_word_and_grammemes reader_word text_word =
  div [] [
    Html.text <| (TextReader.Model.phrase reader_word) ++ " (" ++ TextReader.TextWord.grammemesToString text_word ++ ")"
  ]

view_flashcard_words : Model -> Html Msg
view_flashcard_words model =
  div []
    (List.map (\(normal_form, text_word) -> div [] [ Html.text normal_form ])
    (Dict.toList <| Maybe.withDefault Dict.empty <| User.Profile.TextReader.Flashcards.flashcards model.flashcard))

view_flashcard_options : Model -> TextReaderWord -> Html Msg
view_flashcard_options model reader_word =
  let
    phrase = TextReader.Model.phrase reader_word
    flashcards = Maybe.withDefault Dict.empty (User.Profile.TextReader.Flashcards.flashcards model.flashcard)
    add = div [class "cursor", onClick (AddToFlashcards reader_word)] [ Html.text "Add to Flashcards" ]
    remove = div [class "cursor", onClick (RemoveFromFlashcards reader_word)] [ Html.text "Remove from Flashcards" ]

  in
    div [class "gloss-flashcard-options"] (if Dict.member phrase flashcards then [remove] else [add])

view_gloss : Model -> TextReaderWord -> TextReader.TextWord.TextWord -> Html Msg
view_gloss model reader_word text_word =
  span [] [
    span [ classList [("gloss-overlay", True), ("gloss-menu", True)]
        , onMouseLeave (UnGloss reader_word)
        , classList [("hidden", not (TextReader.Model.selected reader_word model.gloss))]
        ] [
            view_word_and_grammemes reader_word text_word
          , view_translations (TextReader.TextWord.translations text_word)
          , view_flashcard_options model reader_word
          ]
  ]

is_part_of_compound_word : Section -> Int -> String -> Maybe (Int, Int, Int)
is_part_of_compound_word section instance word =
  case TextReader.Section.Model.getTextWord section instance word of
    Just text_word ->
      case (TextReader.TextWord.group text_word) of
        Just group ->
          Just (group.instance, group.pos, group.length)

        Nothing ->
          Nothing

    Nothing ->
      Nothing

view_text_section : Model -> Section -> Html Msg
view_text_section model text_reader_section =
  let
    text_section = TextReader.Section.Model.textSection text_reader_section

    text_body_vdom =
      Text.Section.Words.Tag.tagWordsAndToVDOM
        (tagWord model text_reader_section)
        (is_part_of_compound_word text_reader_section)
        (HtmlParser.parse text_section.body)

    section_title = ("Section " ++ (toString (text_section.order +1)) ++ "/" ++ (toString text_section.num_of_sections))
  in
    div [id "text-body"] <| [
        div [id "title"] [ Html.text section_title ]
      , div [id "body"] text_body_vdom
      , view_questions text_reader_section
    ]

view_text_introduction : Text -> Html Msg
view_text_introduction text =
  div [attribute "id" "text-intro"] (HtmlParser.Util.toVirtualDom <| HtmlParser.parse text.introduction)

view_text_conclusion : Text -> Html Msg
view_text_conclusion text =
  div [attribute "id" "text-conclusion"]
    (HtmlParser.Util.toVirtualDom <| HtmlParser.parse (Maybe.withDefault "" text.conclusion))

view_prev_btn : Html Msg
view_prev_btn =
  div [onClick PrevSection, class "prev-btn"] [
    Html.text "Previous"
  ]

view_next_btn : Html Msg
view_next_btn =
  div [onClick NextSection, class "next-btn"] [
    Html.text "Next"
  ]

view_text_complete : Model -> TextScores -> Html Msg
view_text_complete model scores =
  div [id "complete"] [
    div [attribute "id" "text-score"] [
      div [] [
        Html.text
          (  "You answered "
          ++ (toString scores.section_scores)
          ++ " out of "
          ++ (toString scores.possible_section_scores)
          ++ " questions correctly for this text.")
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
  div [class "exception"]
    (case model.exception of
      Just exception ->
        [
          Html.text exception.error_msg
        ]
      Nothing ->
        [])

view_content : Model -> Html Msg
view_content model =
  let
    content =
      (case model.progress of
        ViewIntro ->
          [
            view_text_introduction model.text
          , div [id "nav", onClick NextSection] [
              div [class "start-btn"] [ Html.text "Start" ]
            ]
          ]

        ViewSection section ->
          [
            view_text_section model section
          , view_exceptions model
          , div [id "nav"] [view_prev_btn, view_next_btn]
          ]

        Complete text_scores ->
          [view_text_complete model text_scores]

        _ ->
          [])
  in
    div [id "text-section"] content