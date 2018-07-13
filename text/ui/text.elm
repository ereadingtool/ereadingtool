import Html exposing (Html, div)
import Html.Attributes exposing (classList, attribute)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import HtmlParser
import HtmlParser.Util

import Http exposing (..)

import Array exposing (Array)

import Text.Model exposing (Text, emptyTextSection)

import Question.Model exposing (Question)
import Question.Decode exposing (questionsDecoder)

import Text.Model as Texts exposing (Text)
import Text.Decode
import Answer.Model exposing (Answer)

import Views
import Profile
import Instructor.Profile

import Config exposing (..)
import Flags exposing (CSRFToken)


type alias Index = Int
type alias ID = String
type alias Name = String

type alias QuestionIndex = Int
type alias TextIndex = Int

type alias Selected = Bool

-- UPDATE
type Msg =
    UpdateTexts (Result Http.Error TextSection)
  | UpdateQuestions TextsText (Result Http.Error (Array Question))
  | Select TextsText TextsQuestion TextsAnswer Bool

type alias Flags = {
    csrftoken : CSRFToken
  , profile_id : Profile.ProfileID
  , profile_type : Profile.ProfileType
  , instructor_profile : Maybe Instructor.Profile.InstructorProfileParams
  , student_profile : Maybe Profile.StudentProfileParams
  , text_id : Int }

type alias Model = {
    text : TextSection
  , profile : Profile.Profile
  , texts : Array TextsText
  , flags : Flags }

type alias TextsItemAttributes a = { a | index : Int }

type alias TextsAnswerAttributes = TextsItemAttributes { question_index : Int, name: String, id: String }
type alias TextsQuestionAttributes = TextsItemAttributes { id:String, text_index: Int }

type TextsAnswer = TextsAnswer Answer TextsAnswerAttributes Selected
type TextsQuestion = TextsQuestion Question TextsQuestionAttributes (Array TextsAnswer)

type TextsText = TextsText TextSection (TextsItemAttributes {}) (Array TextsQuestion)


init : Flags -> (Model, Cmd Msg)
init flags = ({
    text=Texts.new_text
  , texts=Array.fromList []
  , profile=Profile.init_profile flags
  , flags=flags}, updateTexts flags.text_id)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

updateTexts : Int -> Cmd Msg
updateTexts text_id =
  let
    text_req = Http.get (String.join "" [text_section_api_endpoint, (toString text_id)] ++ "/") Text.Decode.textDecoder
  in
    Cmd.batch [Http.send UpdateTexts text_req]

updateTextsForTexts : Array TextsText -> Cmd Msg
updateTextsForTexts text_texts =
     Cmd.batch
  <| List.map updateText
  <| Array.toList text_texts

updateText : TextsText -> Cmd Msg
updateText ((TextsText text attrs questions) as text_text) =
  let
    question_req =
      Http.get (String.join "" [question_api_endpoint, "?", "text", "=", (toString text.id)]) questionsDecoder
  in
    Http.send (UpdateQuestions text_text) question_req

gen_text_answer : Int -> Int -> Answer -> TextsAnswer
gen_text_answer question_index answer_index answer =
  TextsAnswer answer {
    -- question_field_index = question.order
    id = String.join "_" [ "question", (toString question_index), "answer", (toString answer.order) ]
  , name = String.join "_" [ "question", (toString question_index) ]
  , question_index = question_index
  , index = answer_index } False

gen_text_question : Int -> Int -> Question -> TextsQuestion
gen_text_question text_index index question =
  TextsQuestion question
    {index=index, text_index=text_index, id=(toString question.order)}
  (Array.indexedMap (gen_text_answer index) question.answers)

text_text : Array TextsText -> TextsQuestion -> Maybe TextsText
text_text text_texts (TextsQuestion question question_attr answers) =
  Array.get question_attr.text_index text_texts

gen_text_text : Int -> TextSection -> TextsText
gen_text_text index text =
  TextsText text {index=index} (Array.indexedMap (gen_text_question index) text.questions)

set_questions : TextsText -> Array TextsQuestion -> TextsText
set_questions (TextsText text attrs _) new_questions =
  TextsText text attrs new_questions

set_answer_selected : TextsAnswer -> Bool -> TextsAnswer
set_answer_selected (TextsAnswer answer attr _) selected =
  TextsAnswer answer attr selected

set_answer : TextsQuestion -> TextsAnswer -> TextsQuestion
set_answer (TextsQuestion question question_attr answers) ((TextsAnswer _ answer_attr _) as new_text_answer) =
  TextsQuestion question question_attr (Array.set answer_attr.index new_text_answer answers)

set_question : TextsText -> TextsQuestion -> TextsText
set_question (TextsText text text_attr questions) ((TextsQuestion question question_attr answers) as new_text_question) =
  TextsText text text_attr (Array.set question_attr.index new_text_question questions)

set_text : Array TextsText -> TextsText -> Array TextsText
set_text text_texts ((TextsText _ attrs _) as text_text) =
  Array.set attrs.index text_text text_texts

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    UpdateTexts (Ok text) ->
      let
        text_texts = Array.indexedMap gen_text_text text.texts
      in
        ({ model | text = text, texts = text_texts }, Cmd.none)

    UpdateTexts (Err err) ->
      case (Debug.log "text error" err) of
        _ -> (model, Cmd.none)

    UpdateQuestions text_text (Err err) ->
      case (Debug.log "questions error" err) of
        _ -> (model, Cmd.none)

    Select text_text text_question text_answer selected ->
      let
        new_text_answer = set_answer_selected text_answer selected
        new_text_question = set_answer text_question new_text_answer
        new_text_text = set_question text_text new_text_question
        new_text_texts = set_text model.texts new_text_text
      in
        ({ model | texts = new_text_texts }, Cmd.none)

    _ -> (model, Cmd.none)

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

view_answer : TextsText -> TextsQuestion -> TextsAnswer -> Html Msg
view_answer text_text text_question ((TextsAnswer answer answer_attrs answer_selected) as text_answer) =
  div [ classList [("answer", True)] ] [
   Html.input [
     attribute "id" answer_attrs.id
   , attribute "name" answer_attrs.name
   , attribute "type" "radio"
   , onCheck (Select text_text text_question text_answer)
   , attribute "value" (toString answer.order)] []
 , Html.text answer.text
 , (if answer_selected then
     div [] [ Html.em [] [ Html.text answer.feedback ] ] else Html.text "")]

view_question : TextsText -> TextsQuestion -> Html Msg
view_question text_text ((TextsQuestion question attrs answers) as text_question) =
  div [ classList [("question", True)], attribute "id" attrs.id] [
        Html.text question.body
      , div [attribute "class" "answers"] (Array.toList <| Array.map (view_answer text_text text_question) answers)
  ]

view_questions : TextsText -> Html Msg
view_questions ((TextsText text text_attr questions) as text_text) =
  div [ classList[("questions", True)] ] (Array.toList <| Array.map (view_question text_text) questions)

view_text : TextsText -> Html Msg
view_text ((TextsText text attrs questions) as text_text) =
  div [ classList[("text", True)] ] <| [
      div [classList [("text_body", True)]] (HtmlParser.Util.toVirtualDom <| HtmlParser.parse text.body)
    , (view_questions text_text)
  ]

view_text_introduction : Model -> Html Msg
view_text_introduction model =
  div [attribute "id" "text_intro"] (HtmlParser.Util.toVirtualDom <| HtmlParser.parse model.text.introduction)

view_content : Model -> Html Msg
view_content model = div [ classList [("text", True)] ] (Array.toList <| Array.map view_text model.texts)

-- VIEW
view : Model -> Html Msg
view model = div [] [
    (Views.view_header model.profile Nothing)
  , (Views.view_filter)
  , (view_text_introduction model)
  , (view_content model)
  , (Views.view_footer)
  ]
