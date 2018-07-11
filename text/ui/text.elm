import Html exposing (Html, div)
import Html.Attributes exposing (classList, attribute)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import HtmlParser
import HtmlParser.Util

import Http exposing (..)

import Array exposing (Array)

import Text.Model exposing (Text, emptyText)

import Question.Model exposing (Question)
import Question.Decode exposing (questionsDecoder)

import Quiz.Model as Quiz exposing (Quiz)
import Quiz.Decode
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
    UpdateQuiz (Result Http.Error Quiz)
  | UpdateQuestions QuizText (Result Http.Error (Array Question))
  | Select QuizText QuizQuestion QuizAnswer Bool

type alias Flags = {
    csrftoken : CSRFToken
  , profile_id : Profile.ProfileID
  , profile_type : Profile.ProfileType
  , instructor_profile : Maybe Instructor.Profile.InstructorProfileParams
  , student_profile : Maybe Profile.StudentProfileParams
  , quiz_id : Int }

type alias Model = {
    quiz : Quiz
  , profile : Profile.Profile
  , texts : Array QuizText
  , flags : Flags }

type alias QuizItemAttributes a = { a | index : Int }

type alias QuizAnswerAttributes = QuizItemAttributes { question_index : Int, name: String, id: String }
type alias QuizQuestionAttributes = QuizItemAttributes { id:String, text_index: Int }

type QuizAnswer = QuizAnswer Answer QuizAnswerAttributes Selected
type QuizQuestion = QuizQuestion Question QuizQuestionAttributes (Array QuizAnswer)

type QuizText = QuizText Text (QuizItemAttributes {}) (Array QuizQuestion)


init : Flags -> (Model, Cmd Msg)
init flags = ({
    quiz=Quiz.new_quiz
  , texts=Array.fromList []
  , profile=Profile.init_profile flags
  , flags=flags}, updateQuiz flags.quiz_id)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

updateQuiz : Int -> Cmd Msg
updateQuiz quiz_id =
  let
    quiz_req = Http.get (String.join "" [quiz_api_endpoint, (toString quiz_id)] ++ "/") Quiz.Decode.quizDecoder
  in
    Cmd.batch [Http.send UpdateQuiz quiz_req]

updateTextsForQuiz : Array QuizText -> Cmd Msg
updateTextsForQuiz quiz_texts =
     Cmd.batch
  <| List.map updateText
  <| Array.toList quiz_texts

updateText : QuizText -> Cmd Msg
updateText ((QuizText text attrs questions) as quiz_text) =
  let
    question_req =
      Http.get (String.join "" [question_api_endpoint, "?", "text", "=", (toString text.id)]) questionsDecoder
  in
    Http.send (UpdateQuestions quiz_text) question_req

gen_quiz_answer : Int -> Int -> Answer -> QuizAnswer
gen_quiz_answer question_index answer_index answer =
  QuizAnswer answer {
    -- question_field_index = question.order
    id = String.join "_" [ "question", (toString question_index), "answer", (toString answer.order) ]
  , name = String.join "_" [ "question", (toString question_index) ]
  , question_index = question_index
  , index = answer_index } False

gen_quiz_question : Int -> Int -> Question -> QuizQuestion
gen_quiz_question text_index index question =
  QuizQuestion question
    {index=index, text_index=text_index, id=(toString question.order)}
  (Array.indexedMap (gen_quiz_answer index) question.answers)

quiz_text : Array QuizText -> QuizQuestion -> Maybe QuizText
quiz_text quiz_texts (QuizQuestion question question_attr answers) =
  Array.get question_attr.text_index quiz_texts

gen_quiz_text : Int -> Text -> QuizText
gen_quiz_text index text =
  QuizText text {index=index} (Array.indexedMap (gen_quiz_question index) text.questions)

set_questions : QuizText -> Array QuizQuestion -> QuizText
set_questions (QuizText text attrs _) new_questions =
  QuizText text attrs new_questions

set_answer_selected : QuizAnswer -> Bool -> QuizAnswer
set_answer_selected (QuizAnswer answer attr _) selected =
  QuizAnswer answer attr selected

set_answer : QuizQuestion -> QuizAnswer -> QuizQuestion
set_answer (QuizQuestion question question_attr answers) ((QuizAnswer _ answer_attr _) as new_quiz_answer) =
  QuizQuestion question question_attr (Array.set answer_attr.index new_quiz_answer answers)

set_question : QuizText -> QuizQuestion -> QuizText
set_question (QuizText text text_attr questions) ((QuizQuestion question question_attr answers) as new_quiz_question) =
  QuizText text text_attr (Array.set question_attr.index new_quiz_question questions)

set_text : Array QuizText -> QuizText -> Array QuizText
set_text quiz_texts ((QuizText _ attrs _) as quiz_text) =
  Array.set attrs.index quiz_text quiz_texts

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    UpdateQuiz (Ok quiz) ->
      let
        quiz_texts = Array.indexedMap gen_quiz_text quiz.texts
      in
        ({ model | quiz = quiz, texts = quiz_texts }, Cmd.none)

    UpdateQuiz (Err err) ->
      case (Debug.log "quiz error" err) of
        _ -> (model, Cmd.none)

    UpdateQuestions quiz_text (Err err) ->
      case (Debug.log "questions error" err) of
        _ -> (model, Cmd.none)

    Select quiz_text quiz_question quiz_answer selected ->
      let
        new_quiz_answer = set_answer_selected quiz_answer selected
        new_quiz_question = set_answer quiz_question new_quiz_answer
        new_quiz_text = set_question quiz_text new_quiz_question
        new_quiz_texts = set_text model.texts new_quiz_text
      in
        ({ model | texts = new_quiz_texts }, Cmd.none)

    _ -> (model, Cmd.none)

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

view_answer : QuizText -> QuizQuestion -> QuizAnswer -> Html Msg
view_answer quiz_text quiz_question ((QuizAnswer answer answer_attrs answer_selected) as quiz_answer) =
  div [ classList [("answer", True)] ] [
   Html.input [
     attribute "id" answer_attrs.id
   , attribute "name" answer_attrs.name
   , attribute "type" "radio"
   , onCheck (Select quiz_text quiz_question quiz_answer)
   , attribute "value" (toString answer.order)] []
 , Html.text answer.text
 , (if answer_selected then
     div [] [ Html.em [] [ Html.text answer.feedback ] ] else Html.text "")]

view_question : QuizText -> QuizQuestion -> Html Msg
view_question quiz_text ((QuizQuestion question attrs answers) as quiz_question) =
  div [ classList [("question", True)], attribute "id" attrs.id] [
        Html.text question.body
      , div [attribute "class" "answers"] (Array.toList <| Array.map (view_answer quiz_text quiz_question) answers)
  ]

view_questions : QuizText -> Html Msg
view_questions ((QuizText text text_attr questions) as quiz_text) =
  div [ classList[("questions", True)] ] (Array.toList <| Array.map (view_question quiz_text) questions)

view_text : QuizText -> Html Msg
view_text ((QuizText text attrs questions) as quiz_text) =
  div [ classList[("text", True)] ] <| [
      div [classList [("text_body", True)]] (HtmlParser.Util.toVirtualDom <| HtmlParser.parse text.body)
    , (view_questions quiz_text)
  ]

view_quiz_introduction : Model -> Html Msg
view_quiz_introduction model =
  div [attribute "id" "quiz_intro"] (HtmlParser.Util.toVirtualDom <| HtmlParser.parse model.quiz.introduction)

view_content : Model -> Html Msg
view_content model = div [ classList [("quiz", True)] ] (Array.toList <| Array.map view_text model.texts)

-- VIEW
view : Model -> Html Msg
view model = div [] [
    (Views.view_header model.profile Nothing)
  , (Views.view_filter)
  , (view_quiz_introduction model)
  , (view_content model)
  , (Views.view_footer)
  ]
