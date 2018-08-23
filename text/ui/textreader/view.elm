module TextReader.View exposing (..)

import Html exposing (Html, div, span)
import Html.Attributes exposing (class, classList, attribute, property)
import Html.Events exposing (onClick, onDoubleClick)

import Array exposing (Array)
import Dict exposing (Dict)

import TextReader.Model exposing (..)

import TextReader.Text.Model exposing (Text)
import TextReader.Section.Model exposing (Section)
import TextReader.Question.Model exposing (TextQuestion)
import TextReader.Answer.Model exposing (TextAnswer)
import TextReader.Msg exposing (Msg(..))


import HtmlParser
import HtmlParser.Util

import TextReader.Dictionary exposing (dictionary)
import VirtualDom



tagWord : Dict String Bool -> String -> Html Msg
tagWord gloss word =
  if (Dict.member word dictionary) then
    Html.node "span" [class "defined_word", onDoubleClick (Gloss word)] [
      VirtualDom.text word
    , view_gloss gloss word
    ]
  else
    VirtualDom.text word

tagWordAndToVDOM : Dict String Bool -> HtmlParser.Node -> Html Msg
tagWordAndToVDOM gloss node =
  case node of
    HtmlParser.Text str ->
      tagWord gloss str

    HtmlParser.Element name attrs nodes ->
      Html.node name (List.map (\(name, value) -> attribute name value) attrs) (tagWordsAndToVDOM gloss nodes)

    (HtmlParser.Comment str) as comment ->
        VirtualDom.text ""

tagWordsAndToVDOM : Dict String Bool -> List HtmlParser.Node -> List (Html Msg)
tagWordsAndToVDOM gloss text =
  List.map (tagWordAndToVDOM gloss) text

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
    answers = Debug.log "answers" (TextReader.Question.Model.answers text_question)
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

view_gloss : Dict String Bool -> String -> Html Msg
view_gloss gloss word =
  let
    word_def = (flip Dict.get) dictionary >> Maybe.withDefault ""
  in
    div []
      (List.map
        (\word ->
          div [ classList [("gloss_overlay", True), ("gloss_menu", True)
              , ("hidden", not (Dict.member word gloss))]
              , onClick (UnGloss word)] [
            Html.text (word ++ " : " ++ word_def word)
          ]
        ) (Dict.keys gloss))

view_text_section : Dict String Bool -> Section -> Html Msg
view_text_section gloss section =
  let
    text_section = TextReader.Section.Model.text_section section
    text_body_vdom = tagWordsAndToVDOM gloss (HtmlParser.parse text_section.body)
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
  div [attribute "id" "text_conclusion"] (HtmlParser.Util.toVirtualDom <| HtmlParser.parse text.conclusion)

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
        view_text_section model.gloss section
      , view_exceptions model
      , div [class "nav"] [view_prev_btn, view_next_btn]
      ]

    Complete text_scores ->
      view_text_complete model text_scores

    _ ->
      div [] []
