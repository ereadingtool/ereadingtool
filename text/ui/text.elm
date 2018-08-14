import Html exposing (Html, div, span)
import Html.Attributes exposing (class, classList, attribute, property)
import Html.Events exposing (onClick, onDoubleClick)

import HtmlParser
import HtmlParser.Util

import Http exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)

import Text.Section.Model exposing (TextSection, emptyTextSection)
import Text.Model exposing (Text)

import Text.Model as Texts exposing (Text)
import Text.Decode

import Views
import Profile

import Config exposing (..)
import Flags exposing (CSRFToken)

import VirtualDom

import WebSocket

import TextReader exposing (TextItemAttributes)
import TextReader.Question exposing (TextQuestion)
import TextReader.Answer exposing (TextAnswer)

import TextReader.Dictionary exposing (dictionary)


type Section = Section TextSection (TextItemAttributes {}) (Array TextQuestion)

type Progress = ViewIntro | ViewSection Int | Complete

type alias Word = String

-- UPDATE
type Msg =
    UpdateText (Result Http.Error Text)
  | Select Section TextQuestion TextAnswer Bool
  | ViewFeedback Section TextQuestion TextAnswer Bool
  | PrevSection
  | NextSection
  | StartOver
  | Gloss Word
  | UnGloss Word

type alias Flags = Flags.Flags { text_id : Int }

type alias Model = {
    text : Text
  , profile : Profile.Profile
  , progress: Progress
  , sections : Array Section
  , gloss : Dict String Bool
  , flags : Flags }

init : Flags -> (Model, Cmd Msg)
init flags =
  let
    profile = Profile.init_profile flags
  in
    ({ text=Texts.new_text
     , sections=Array.fromList []
     , gloss=Dict.empty
     , profile=profile
     , progress=ViewIntro
     , flags=flags }
    , Cmd.batch [updateText flags.text_id])

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

start : Profile.Profile -> Cmd Msg
start profile =
  case profile of
    Profile.Student profile ->
      let
        student_username = Profile.studentUserName profile
        _ = Debug.log "username" student_username
      in
        WebSocket.send "ws://0.0.0.0:8000/text_reader/" ("{\"test\":\"" ++ student_username ++ "\"}")
    _ ->
      Cmd.none

updateText : Int -> Cmd Msg
updateText text_id =
  let
    text_req = Http.get (String.join "" [text_api_endpoint, (toString text_id)] ++ "/") Text.Decode.textDecoder
  in
    Http.send UpdateText text_req

update_completed_section : Int -> Int -> Array Section -> Cmd Msg
update_completed_section section_id section_index sections =
  Cmd.none

text_section : Array Section -> TextQuestion -> Maybe Section
text_section text_sections text_question =
  let
    text_section_index = TextReader.Question.text_section_index text_question
  in
    Array.get text_section_index text_sections

gen_text_sections : Int -> TextSection -> Section
gen_text_sections index text_section =
  Section
    text_section {index=index} (Array.indexedMap (TextReader.Question.gen_text_question index) text_section.questions)

clear_question_answers : Section -> Section
clear_question_answers section =
  let
    new_questions = Array.map (\question -> TextReader.Question.deselect_all_answers question) (questions section)
  in
    set_questions section new_questions

questions : Section -> Array TextQuestion
questions (Section section attrs questions) = questions

complete : Section -> Bool
complete section =
     List.all (\answered -> answered)
  <| Array.toList
  <| Array.map (\question -> TextReader.Question.answered question) (questions section)

completed_sections : Array Section -> Int
completed_sections sections =
     List.sum
  <| Array.toList
  <| Array.map (\section -> if (complete section) then 1 else 0) sections

max_score : Section -> Int
max_score section =
     List.sum
  <| Array.toList
  <| Array.map (\question -> 1) (questions section)

score : Section -> Int
score section =
     List.sum
  <| Array.toList
  <| Array.map (\question ->
       if (Maybe.withDefault False (TextReader.Question.answered_correctly question)) then 1 else 0) (questions section)

set_questions : Section -> Array TextQuestion -> Section
set_questions (Section text attrs _) new_questions =
  Section text attrs new_questions

set_question : Section -> TextQuestion -> Section
set_question (Section text text_attr questions) new_text_question =
  let
    question_index = TextReader.Question.index new_text_question
  in
    Section text text_attr (Array.set question_index new_text_question questions)

set_text_section : Array Section -> Section -> Array Section
set_text_section text_sections ((Section _ attrs _) as text_section) =
  Array.set attrs.index text_section text_sections

tagWord : Dict String Bool -> String -> Html Msg
tagWord gloss word =
  if (Dict.member word dictionary) then
    Html.node "span" [class "defined_word", onDoubleClick (Gloss word)] [
      VirtualDom.text word, view_gloss gloss word
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

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
    update_question text_section new_text_question =
      let
        new_text_section = set_question text_section new_text_question
      in
        set_text_section model.sections new_text_section
  in
    case msg of
      Gloss word ->
        ({ model | gloss = Dict.insert word True model.gloss }, Cmd.none)

      UnGloss word ->
        ({ model | gloss = Dict.remove word model.gloss }, Cmd.none)

      UpdateText (Ok text) ->
        let
          text_sections = Array.indexedMap gen_text_sections text.sections
        in
          ({ model | text = text, sections = text_sections }, Cmd.none)

      UpdateText (Err err) ->
        case (Debug.log "text error" err) of
          _ -> (model, Cmd.none)

      Select text_section text_question text_answer selected ->
        let
          new_text_answer = TextReader.Answer.set_answer_selected text_answer selected
          new_text_question = TextReader.Question.set_as_submitted_answer text_question new_text_answer
        in
          ({ model | sections = (update_question text_section new_text_question) }, Cmd.none)

      ViewFeedback text_section text_question text_answer view_feedback ->
        let
          new_text_answer = TextReader.Answer.set_answer_feedback_viewable text_answer view_feedback
          new_text_question = TextReader.Question.set_answer text_question new_text_answer
        in
          ({ model | sections = (update_question text_section new_text_question) }, Cmd.none)

      StartOver ->
        let
          new_sections = Array.map (\section -> clear_question_answers section) model.sections
        in
          ({ model | sections = new_sections, progress = ViewIntro}, Cmd.none)

      NextSection ->
        case model.progress of
          ViewIntro ->
            ({ model | progress = ViewSection 0 }, Cmd.none)

          ViewSection i ->
            let
              new_progress =
                (case Array.get (i+1) model.sections of
                  Just next_section ->
                    ViewSection (i+1)
                  Nothing ->
                    Complete)
            in
              ({ model | progress = new_progress }, Cmd.none)

          Complete ->
            (model, Cmd.none)

      PrevSection ->
        case model.progress of
          ViewIntro ->
            (model, Cmd.none)

          ViewSection i ->
            let
              prev_section_index = i-1
            in
              case Array.get prev_section_index model.sections of
                Just prev_section ->
                  ({ model | progress = ViewSection prev_section_index }, Cmd.none)
                Nothing ->
                  ({ model | progress = ViewIntro }, Cmd.none)

          Complete ->
            let
              last_section_index = (Array.length model.sections) - 1
            in
              case Array.get last_section_index model.sections of
                Just section ->
                  ({ model | progress = ViewSection last_section_index }, Cmd.none)
                Nothing ->
                  (model, Cmd.none)

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

view_answer : Section -> TextQuestion -> TextAnswer -> Html Msg
view_answer text_section text_question text_answer =
  let
    question_answered = TextReader.Question.answered text_question

    on_click =
      if question_answered then
        onClick (ViewFeedback text_section text_question text_answer True)
      else
        onClick (Select text_section text_question text_answer True)

    answer = TextReader.Answer.answer text_answer
    answer_selected = TextReader.Answer.selected text_answer
    is_correct = TextReader.Answer.correct text_answer
    view_feedback = TextReader.Answer.feedback_viewable text_answer
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
    text_question_id = TextReader.Question.id text_question
    question = TextReader.Question.question text_question
    answers = TextReader.Question.answers text_question
  in
    div [class "question", attribute "id" text_question_id] [
      div [class "question_body"] [ Html.text question.body ]
    , div [class "answers"]
        (Array.toList <| Array.map (view_answer text_section text_question) answers)
    ]

view_questions : Section -> Html Msg
view_questions ((Section text text_attr questions) as text_section) =
  div [class "questions"] (Array.toList <| Array.map (view_question text_section) questions)

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

view_text_section : Dict String Bool -> Int -> Section -> Int -> Html Msg
view_text_section gloss i ((Section text attrs questions) as text_section) total_sections =
  let
    text_body_vdom = tagWordsAndToVDOM gloss (HtmlParser.parse text.body)
  in
    div [class "text_section"] <| [
        div [class "section_title"] [ Html.text ("Section " ++ (toString (i+1)) ++ "/" ++ (toString total_sections)) ]
      , div [class "text_body"] text_body_vdom
      , view_questions text_section
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

view_text_complete : Model -> Html Msg
view_text_complete model =
  let
    num_of_sections = Array.length model.sections
    complete_sections = completed_sections model.sections
    section_scores =
         List.sum
      <| Array.toList
      <| Array.map (\section -> score section) model.sections
    possible_section_scores =
         List.sum
      <| Array.toList
      <| Array.map (\section -> max_score section) model.sections
  in
    div [class "text"] [
      div [attribute "id" "text_score"] [
        Html.text
          ("Sections complete: " ++ (toString complete_sections) ++ "/" ++ (toString num_of_sections))
      , div [] [
          Html.text ("Score: " ++ (toString section_scores) ++ " out of " ++ (toString possible_section_scores))
        ]
      ]
    , view_text_conclusion model.text
    , div [class "nav"] [
        view_prev_btn
      , div [attribute "id" "goback", onClick StartOver] [ Html.text "Start Over" ]
      ]
    ]

view_content : Model -> Html Msg
view_content model =
  let
    total_sections = Array.length model.sections
  in
    case model.progress of
      ViewIntro ->
        div [class "text"] <| [
          view_text_introduction model.text
        , div [onClick NextSection, class "nav"] [ div [class "start_btn"] [ Html.text "Start" ] ]
        ]

      ViewSection i ->
        div [class "text"]
          (case Array.get i model.sections of
            Just section ->
              [ view_text_section model.gloss i section total_sections
              , div [class "nav"] [view_prev_btn, view_next_btn] ]
            Nothing ->
              [])

      Complete ->
        view_text_complete model

-- VIEW
view : Model -> Html Msg
view model = div [] [
    (Views.view_header model.profile Nothing)
  , (Views.view_filter)
  , (view_content model)
  , (Views.view_footer)
  ]
