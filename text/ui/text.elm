import Html exposing (Html, div)
import Html.Attributes exposing (class, classList, attribute)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import HtmlParser
import HtmlParser.Util

import Http exposing (..)

import Array exposing (Array)

import Text.Section.Model exposing (TextSection, emptyTextSection)
import Text.Model exposing (Text)

import Question.Model exposing (Question)

import Text.Model as Texts exposing (Text)
import Text.Decode
import Answer.Model exposing (Answer)

import Views
import Profile

import Config exposing (..)
import Flags exposing (CSRFToken)

import WebSocket


type alias Selected = Bool
type alias AnsweredCorrectly = Bool

type alias TextItemAttributes a = { a | index : Int }

type alias TextAnswerAttributes = TextItemAttributes { question_index : Int, name: String, id: String }
type alias TextQuestionAttributes = TextItemAttributes { id:String, text_section_index: Int }

type TextAnswer = TextAnswer Answer TextAnswerAttributes Selected
type TextQuestion = TextQuestion Question TextQuestionAttributes AnsweredCorrectly (Array TextAnswer)

type Section = Section TextSection (TextItemAttributes {}) (Array TextQuestion)

type Progress = ViewIntro | ViewSection Int | Complete

-- UPDATE
type Msg =
    UpdateText (Result Http.Error Text)
  | Select Section TextQuestion TextAnswer Bool
  | PrevSection
  | NextSection

type alias Flags = Flags.Flags { text_id : Int }

type alias Model = {
    text : Text
  , profile : Profile.Profile
  , progress: Progress
  , sections : Array Section
  , flags : Flags }

init : Flags -> (Model, Cmd Msg)
init flags =
  let
    profile = Profile.init_profile flags
  in
    ({ text=Texts.new_text
     , sections=Array.fromList []
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
    Cmd.batch [Http.send UpdateText text_req]

gen_text_answer : Int -> Int -> Answer -> TextAnswer
gen_text_answer question_index answer_index answer =
  TextAnswer answer {
    -- question_field_index = question.order
    id = String.join "_" [ "question", (toString question_index), "answer", (toString answer.order) ]
  , name = String.join "_" [ "question", (toString question_index) ]
  , question_index = question_index
  , index = answer_index } False

gen_text_question : Int -> Int -> Question -> TextQuestion
gen_text_question text_section_index index question =
  TextQuestion question
    {index=index, text_section_index=text_section_index, id=(toString question.order)}
  False (Array.indexedMap (gen_text_answer index) question.answers)

text_section : Array Section -> TextQuestion -> Maybe Section
text_section text_sections (TextQuestion question question_attr _ answers) =
  Array.get question_attr.text_section_index text_sections

gen_text_sections : Int -> TextSection -> Section
gen_text_sections index text_section =
  Section text_section {index=index} (Array.indexedMap (gen_text_question index) text_section.questions)

questions : Section -> Array TextQuestion
questions (Section section attrs questions) = questions

answers : TextQuestion -> Array TextAnswer
answers (TextQuestion _ _ _ answers) = answers

answered_correctly : TextQuestion -> Bool
answered_correctly (TextQuestion _ _ answered_correctly _) = answered_correctly

answered : TextQuestion -> Bool
answered text_question =
     List.any (\selected -> selected)
  <| Array.toList
  <| Array.map (\answer -> selected answer) (answers text_question)

complete : Section -> Bool
complete section =
     List.all (\answered -> answered)
  <| Array.toList
  <| Array.map (\question -> answered question) (questions section)

max_score : Section -> Int
max_score section =
     List.sum
  <| Array.toList
  <| Array.map (\question -> 1) (questions section)

score : Section -> Int
score section =
     List.sum
  <| Array.toList
  <| Array.map (\question -> if (answered_correctly question) then 1 else 0) (questions section)

set_questions : Section -> Array TextQuestion -> Section
set_questions (Section text attrs _) new_questions =
  Section text attrs new_questions

set_answer_selected : TextAnswer -> Bool -> TextAnswer
set_answer_selected (TextAnswer answer attr _) selected =
  TextAnswer answer attr selected

correct : TextAnswer -> Bool
correct text_answer = (answer text_answer).correct

selected : TextAnswer -> Bool
selected (TextAnswer _ _ selected) = selected

answer : TextAnswer -> Answer
answer (TextAnswer answer attr selected) = answer

set_answer : TextQuestion -> TextAnswer -> TextQuestion
set_answer (TextQuestion question question_attr _ answers) ((TextAnswer _ answer_attr _) as new_text_answer) =
  let
    answered_correctly = (correct new_text_answer) && (selected new_text_answer)
  in
    TextQuestion question question_attr answered_correctly (Array.set answer_attr.index new_text_answer answers)

set_question : Section -> TextQuestion -> Section
set_question (Section text text_attr questions) ((TextQuestion question question_attr _ answers) as new_text_question) =
  Section text text_attr (Array.set question_attr.index new_text_question questions)

set_text_section : Array Section -> Section -> Array Section
set_text_section text_texts ((Section _ attrs _) as text_text) =
  Array.set attrs.index text_text text_texts

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
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
        new_text_answer = set_answer_selected text_answer selected
        new_text_question = set_answer text_question new_text_answer
        new_text_section = set_question text_section new_text_question
        new_sections = set_text_section model.sections new_text_section
      in
        ({ model | sections = new_sections }, Cmd.none)

    NextSection ->
      case model.progress of
        ViewIntro ->
          ({ model | progress = ViewSection 0 }, Cmd.none)
        ViewSection i ->
          case Array.get (i+1) model.sections of
            Just next_section ->
              ({ model | progress = ViewSection (i+1) }, Cmd.none)
            Nothing ->
              ({ model | progress = Complete }, Cmd.none)
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
view_answer text_section text_question ((TextAnswer answer answer_attrs answer_selected) as text_answer) =
  div [ classList [("answer", True)] ] [
   Html.input ([
     attribute "id" answer_attrs.id
   , attribute "name" answer_attrs.name
   , attribute "type" "radio"
   , onCheck (Select text_section text_question text_answer)
   , attribute "value" (toString answer.order)
   ] ++ (if answer_selected then [attribute "checked" "true"] else [])) []
 , Html.text answer.text
 , (if answer_selected then
     div [] [ Html.em [] [ Html.text answer.feedback ] ] else Html.text "")]

view_question : Section -> TextQuestion -> Html Msg
view_question text_section ((TextQuestion question attrs answered_correctly answers) as text_question) =
  div [ classList [("question", True)], attribute "id" attrs.id] [
        Html.text question.body
      , div [attribute "class" "answers"]
          (Array.toList <| Array.map (view_answer text_section text_question) answers)
  ]

view_questions : Section -> Html Msg
view_questions ((Section text text_attr questions) as text_section) =
  div [ classList[("questions", True)] ] (Array.toList <| Array.map (view_question text_section) questions)

view_text_section : Int -> Section -> Html Msg
view_text_section i ((Section text attrs questions) as text_section) =
  div [ classList[("text_section", True)] ] <| [
      div [] [ Html.text ("Section " ++ (toString (i+1))) ]
    , div [classList [("text_body", True)]] (HtmlParser.Util.toVirtualDom <| HtmlParser.parse text.body)
    , (view_questions text_section)
  ]

view_text_introduction : Text -> Html Msg
view_text_introduction text =
  div [attribute "id" "text_intro"] (HtmlParser.Util.toVirtualDom <| HtmlParser.parse text.introduction)

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
    complete_sections =
         List.sum
      <| Array.toList
      <| Array.map (\section -> if (complete section) then 1 else 0) model.sections
    section_scores =
         List.sum
      <| Array.toList
      <| Array.map (\section -> score section) model.sections
    possible_section_scores =
         List.sum
      <| Array.toList
      <| Array.map (\section -> max_score section) model.sections
  in
    div [ classList [("text", True)] ] [
      div [attribute "id" "text_score"] [
        Html.text
          ("Sections complete: " ++ (toString complete_sections) ++ "/" ++ (toString num_of_sections))
      , div [] [
          Html.text ("Score: " ++ (toString section_scores) ++ " out of " ++ (toString possible_section_scores))
        ]
      ]
    , view_prev_btn
    ]

view_content : Model -> Html Msg
view_content model =
  case model.progress of
    ViewIntro ->
      div [ classList [("text", True)] ] <| [
        view_text_introduction model.text
      , div [onClick NextSection, class "begin_btn"] [ Html.text "Start" ]
      ]
    ViewSection i ->
      case Array.get i model.sections of
        Just section ->
          div [ classList [("text", True)] ] [
            view_text_section i section
          , view_prev_btn
          , view_next_btn
          ]
        Nothing ->
          div [ classList [("text", True)] ] []
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
