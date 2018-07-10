import Html exposing (Html, div)
import Html.Attributes exposing (classList, attribute)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import HtmlParser
import HtmlParser.Util

import Http exposing (..)

import Array exposing (Array)

import Text.Model exposing (Text, new_text)

import Question.Model exposing (Question)
import Question.Decode exposing (questionsDecoder)

import Text.Model as Text exposing (Text)
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
    UpdateText (Result Http.Error Text)
  | UpdateQuestions TextText (Result Http.Error (Array Question))
  | Select TextText TextQuestion TextAnswer Bool

type alias Flags = {
    csrftoken : CSRFToken
  , profile_id : Profile.ProfileID
  , profile_type : Profile.ProfileType
  , instructor_profile : Maybe Instructor.Profile.InstructorProfileParams
  , student_profile : Maybe Profile.StudentProfileParams
  , text_id : Int }

type alias Model = {
    text : Text
  , profile : Profile.Profile
  , texts : Array TextText
  , flags : Flags }

type alias TextItemAttributes a = { a | index : Int }

type alias TextAnswerAttributes = TextItemAttributes { question_index : Int, name: String, id: String }
type alias TextQuestionAttributes = TextItemAttributes { id:String, text_index: Int }

type TextAnswer = TextAnswer Answer TextAnswerAttributes Selected
type TextQuestion = TextQuestion Question TextQuestionAttributes (Array TextAnswer)

type TextText = TextText Text (TextItemAttributes {}) (Array TextQuestion)


init : Flags -> (Model, Cmd Msg)
init flags = ({
    text=Text.new_text
  , texts=Array.fromList []
  , profile=Profile.init_profile flags
  , flags=flags}, updateText flags.text_id)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

updateText : Int -> Cmd Msg
updateText text_id =
  let
    text_req = Http.get (String.join "" [text_api_endpoint, (toString text_id)] ++ "/") Text.Decode.textDecoder
  in
    Cmd.batch [Http.send UpdateText text_req]

updateTextsForText : Array TextText -> Cmd Msg
updateTextsForText text_texts =
     Cmd.batch
  <| List.map updateText
  <| Array.toList text_texts

updateText : TextText -> Cmd Msg
updateText ((TextText text attrs questions) as text_text) =
  let
    question_req =
      Http.get (String.join "" [question_api_endpoint, "?", "text", "=", (toString text.id)]) questionsDecoder
  in
    Http.send (UpdateQuestions text_text) question_req

gen_text_answer : Int -> Int -> Answer -> TextAnswer
gen_text_answer question_index answer_index answer =
  TextAnswer answer {
    -- question_field_index = question.order
    id = String.join "_" [ "question", (toString question_index), "answer", (toString answer.order) ]
  , name = String.join "_" [ "question", (toString question_index) ]
  , question_index = question_index
  , index = answer_index } False

gen_text_question : Int -> Int -> Question -> TextQuestion
gen_text_question text_index index question =
  TextQuestion question
    {index=index, text_index=text_index, id=(toString question.order)}
  (Array.indexedMap (gen_text_answer index) question.answers)

text_text : Array TextText -> TextQuestion -> Maybe TextText
text_text text_texts (TextQuestion question question_attr answers) =
  Array.get question_attr.text_index text_texts

gen_text_text : Int -> Text -> TextText
gen_text_text index text =
  TextText text {index=index} (Array.indexedMap (gen_text_question index) text.questions)

set_questions : TextText -> Array TextQuestion -> TextText
set_questions (TextText text attrs _) new_questions =
  TextText text attrs new_questions

set_answer_selected : TextAnswer -> Bool -> TextAnswer
set_answer_selected (TextAnswer answer attr _) selected =
  TextAnswer answer attr selected

set_answer : TextQuestion -> TextAnswer -> TextQuestion
set_answer (TextQuestion question question_attr answers) ((TextAnswer _ answer_attr _) as new_text_answer) =
  TextQuestion question question_attr (Array.set answer_attr.index new_text_answer answers)

set_question : TextText -> TextQuestion -> TextText
set_question (TextText text text_attr questions) ((TextQuestion question question_attr answers) as new_text_question) =
  TextText text text_attr (Array.set question_attr.index new_text_question questions)

set_text : Array TextText -> TextText -> Array TextText
set_text text_texts ((TextText _ attrs _) as text_text) =
  Array.set attrs.index text_text text_texts

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    UpdateText (Ok text) ->
      let
        text_texts = Array.indexedMap gen_text_text text.texts
      in
        ({ model | text = text, texts = text_texts }, Cmd.none)

    UpdateText (Err err) ->
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

view_answer : TextText -> TextQuestion -> TextAnswer -> Html Msg
view_answer text_text text_question ((TextAnswer answer answer_attrs answer_selected) as text_answer) =
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

view_question : TextText -> TextQuestion -> Html Msg
view_question text_text ((TextQuestion question attrs answers) as text_question) =
  div [ classList [("question", True)], attribute "id" attrs.id] [
        Html.text question.body
      , div [attribute "class" "answers"] (Array.toList <| Array.map (view_answer text_text text_question) answers)
  ]

view_questions : TextText -> Html Msg
view_questions ((TextText text text_attr questions) as text_text) =
  div [ classList[("questions", True)] ] (Array.toList <| Array.map (view_question text_text) questions)

view_text : TextText -> Html Msg
view_text ((TextText text attrs questions) as text_text) =
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
