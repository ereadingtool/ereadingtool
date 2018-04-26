import Html exposing (Html, div)
import Html.Attributes exposing (classList, attribute)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import HtmlParser
import HtmlParser.Util

import Http exposing (..)

import Array exposing (Array)

import Model exposing (Text, Question, Answer, emptyText, textDecoder, questionsDecoder )
import Views exposing (view_filter, view_header, view_footer)
import Config exposing (..)
import Flags exposing (CSRFToken)

-- UPDATE
type Msg =
    UpdateText (Result Http.Error Text)
  | UpdateQuestions (Result Http.Error (List Question))
  | Select QuestionField AnswerField Bool

type alias Flags = {
    csrftoken : CSRFToken
  , quiz_id : Int }

type alias Model = {
    text : Text
  , question_fields : Array QuestionField
  , flags : Flags }

type alias AnswerField = {
    id : String
  , name : String
  , answer : Answer
  , question_field_index : Int
  , selected : Bool
  , index : Int }

type alias QuestionField = {
    id : String
  , question : Question
  , answer_fields : Array AnswerField
  , index : Int }


init : Flags -> (Model, Cmd Msg)
init flags = (Model emptyText (Array.fromList []) flags, (updateText flags.quiz_id))

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

updateText : Int -> Cmd Msg
updateText text_id =
  let
    text_req = Http.get (String.join "" [text_api_endpoint, (toString text_id)]) textDecoder
    question_req = Http.get (String.join "" [question_api_endpoint, "?", "text", "=", (toString text_id)]) questionsDecoder
  in
    Cmd.batch [Http.send UpdateText text_req, Http.send UpdateQuestions question_req]

gen_answer_field : Int -> Int -> Answer -> AnswerField
gen_answer_field question_field_index answer_index answer = {
    -- question_field_index = question.order
    id = String.join "_" [ "question", (toString question_field_index), "answer", (toString answer.order) ]
  , name = String.join "_" [ "question", (toString question_field_index) ]
  , answer = answer
  , question_field_index = question_field_index
  , selected = False
  , index = answer_index }

gen_question_field : Int -> Question -> QuestionField
gen_question_field index question = {
    id = (toString question.order)
  , index = index
  , question = question
  , answer_fields = Array.indexedMap (\i a -> gen_answer_field index i a) question.answers }

update_answer_field : AnswerField -> Array AnswerField -> Array AnswerField
update_answer_field answer_field answer_fields = Array.set answer_field.index answer_field answer_fields

update_question_field : QuestionField -> Array QuestionField -> Array QuestionField
update_question_field question_field question_fields = Array.set question_field.index question_field question_fields

unselect_answer_fields : Array AnswerField -> Array AnswerField
unselect_answer_fields answer_fields = Array.map (\answer_field -> { answer_field | selected = False } ) answer_fields

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    UpdateText (Ok text) ->
      ({ model | text = text }, Cmd.none)
    UpdateQuestions (Ok questions) ->
      ({ model |
        question_fields = Array.indexedMap (\i q -> gen_question_field i q) (Array.fromList questions) }, Cmd.none )

    UpdateText (Err err) -> case (Debug.log "text error" err) of
      _ -> (model, Cmd.none)
    UpdateQuestions (Err err) -> case (Debug.log "questions error" err) of
      _ -> (model, Cmd.none)

    Select question_field answer_field selected ->
      let new_answer_field = { answer_field | selected = selected }
          new_question_field =
        { question_field
         | answer_fields = update_answer_field new_answer_field (unselect_answer_fields question_field.answer_fields) }
      in
        ({ model
         | question_fields = update_question_field new_question_field model.question_fields }, Cmd.none)

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

view_answer : QuestionField -> AnswerField -> Html Msg
view_answer question_field answer_field = div [ classList [("answer", True)] ] [
   Html.input [
     attribute "id" answer_field.id
   , attribute "name" answer_field.name
   , attribute "type" "radio"
   , onCheck (Select question_field answer_field)
   , attribute "value" (toString answer_field.answer.order)] []
 , Html.text answer_field.answer.text
 , (if answer_field.selected then
     div [] [ Html.em [] [ Html.text answer_field.answer.feedback ] ] else Html.text "")]

view_answers : QuestionField -> Html Msg
view_answers question_field =
  div [] (Array.toList <| Array.map (view_answer question_field) question_field.answer_fields)

view_question : QuestionField -> Html Msg
view_question question_field = let
    question = question_field.question
  in
    div [ classList [("question", True)], attribute "id" question_field.id] [
        Html.text question.body
      , (view_answers question_field)
    ]

view_questions : Array QuestionField -> Html Msg
view_questions questions = div [ classList[("questions", True)] ] (Array.toList <| Array.map view_question questions)

view_text : Text -> Html Msg
view_text text = div [ classList[("text", True)] ] [
    div [classList [("text_body", True)]] (HtmlParser.Util.toVirtualDom <| HtmlParser.parse text.body)
 ]

view_content : Model -> Html Msg
view_content model = div [ classList [("quiz", True)] ] [
    (view_text model.text)
  , (view_questions model.question_fields) ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    (view_header)
  , (view_filter)
  , (view_content model)
  , (view_footer)
  ]
