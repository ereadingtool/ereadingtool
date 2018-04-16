import Html exposing (Html, div)
import Html.Attributes exposing (classList, attribute)

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

type alias Flags = {
    csrftoken : CSRFToken
  , quiz_id : Int }

type alias Model = {
    text : Text
  , questions : Array Question
  , flags : Flags }

init : Flags -> (Model, Cmd Msg)
init flags = (Model emptyText (Array.fromList []) flags, (updateText flags.quiz_id))

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

updateText : Int -> Cmd Msg
updateText text_id =
  let text_req = Http.get (String.join "" [text_api_endpoint, (toString text_id)]) textDecoder in
  let question_req = Http.get (String.join "" [question_api_endpoint, "?", "text", "=", (toString text_id)]) questionsDecoder
  in Cmd.batch [Http.send UpdateText text_req, Http.send UpdateQuestions question_req]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    UpdateText (Ok text) ->
      ({ model | text = text }, Cmd.none)
    UpdateQuestions (Ok questions) ->
      ({ model | questions = Array.fromList questions }, Cmd.none)

    UpdateText (Err err) -> case (Debug.log "text error" err) of
      _ -> (model, Cmd.none)
    UpdateQuestions (Err err) -> case (Debug.log "questions error" err) of
      _ -> (model, Cmd.none)


main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

view_answer : Answer -> Html Msg
view_answer answer = div [ classList [("answer", True)] ] [ Html.text answer.text ]

view_answers : Array Answer -> Html Msg
view_answers answers = div [] (Array.toList <| Array.map view_answer answers)

view_question : Question -> Html Msg
view_question question = div [ classList [("question", True)] ] [
    Html.text question.body
  , (view_answers question.answers) ]

view_questions : Array Question -> Html Msg
view_questions questions = div [ classList[("questions", True)] ] (Array.toList <| Array.map view_question questions)

view_text : Text -> Html Msg
view_text text = div [ classList[("text", True)] ] [
    div [classList [("text_body", True)]] [ Html.iframe [attribute "srcdoc" text.body] [ ] ]
 ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    (view_header)
  , (view_filter)
  , (view_text model.text)
  , (view_questions model.questions)
  , (view_footer)
  ]
