import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Http
import HttpHelpers exposing (post_with_headers)

import Config exposing (text_api_endpoint, quiz_api_endpoint)
import Flags exposing (CSRFToken, Flags)

import Quiz.Model as Quiz exposing (Quiz)
import Quiz.Encode

import Views
import Profile
import Debug
import Json.Decode as Decode

import Text.Model exposing (Text, TextDifficulty)

import Field
import Text.View
import Text.Update

import Text.Component.Group exposing (TextComponentGroup)
import Text.Subscriptions

import Ports exposing (selectAllInputText)

import Text.Decode
import Array exposing (Array)


type QuizField = QuizField (Field.FieldAttributes {
    name : String
  , view : Quiz -> QuizField -> Html Msg
  , edit : Quiz -> QuizField -> Html Msg })

new_quiz_field : Field.FieldAttributes {
    name : String
  , view : Quiz -> QuizField -> Html Msg
  , edit : Quiz -> QuizField -> Html Msg } -> QuizField
new_quiz_field attrs = QuizField attrs

update_quiz_field : Array QuizField -> QuizField -> Array QuizField
update_quiz_field quiz_fields ((QuizField attrs) as quiz_field) = Array.set attrs.index quiz_field quiz_fields

update_editable : QuizField -> Bool -> QuizField
update_editable (QuizField attrs) editable = QuizField { attrs | editable = editable }

type Msg =
    UpdateTextDifficultyOptions (Result Http.Error (List TextDifficulty))
  | SubmitQuiz
  | Submitted (Result Http.Error Text.Decode.TextCreateResp)
  | TextComponentMsg Text.Update.Msg
  | ToggleEditable QuizField Bool
  | UpdateQuizAttributes String String

type alias Model = {
    flags : Flags
  , profile : Profile.Profile
  , success_msg : Maybe String
  , error_msg : Maybe Text.Decode.TextCreateRespError
  , quiz : Quiz
  , quiz_fields : Array QuizField
  , question_difficulties : List TextDifficulty }

type alias Filter = List String

init : Flags -> (Model, Cmd Msg)
init flags = ({
        flags=flags
      , success_msg=Nothing
      , error_msg=Nothing
      , profile=Profile.init_profile flags
      , quiz=Quiz.emptyQuiz
      , quiz_fields=Array.fromList [
          (new_quiz_field { id="quiz_title"
          , editable=False
          , error=False
          , view=view_quiz_title
          , name="title"
          , edit=edit_quiz_title
          , index=0 })
      ]
      , question_difficulties=[]
  }, retrieveTextDifficultyOptions)

textDifficultyDecoder : Decode.Decoder (List TextDifficulty)
textDifficultyDecoder = Decode.keyValuePairs Decode.string

retrieveTextDifficultyOptions : Cmd Msg
retrieveTextDifficultyOptions =
  let request = Http.get (String.join "?" [text_api_endpoint, "difficulties=list"]) textDifficultyDecoder
  in Http.send UpdateTextDifficultyOptions request


update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
    TextComponentMsg msg -> (Text.Update.update msg model)

    SubmitQuiz -> ({ model | error_msg = Nothing, success_msg = Nothing }
      , post_quiz model.flags.csrftoken model.quiz)

    Submitted (Ok text_create_resp) -> case text_create_resp.id of
       Just text_id -> ({ model
         | success_msg = Just <| String.join " " <| [" success!", toString text_id]}, Cmd.none)
       _ -> (model, Cmd.none)

    Submitted (Err err) -> case err of
      Http.BadStatus resp -> case (Text.Decode.decodeCreateRespErrors (Debug.log "errors" resp.body)) of
        Ok errors -> let
          _ = (Debug.log "displaying validations" errors)
          new_text_components = Text.Component.Group.update_errors (Quiz.text_components model.quiz) errors
        in ({ model | quiz = (Quiz.set_text_components model.quiz new_text_components) }, Cmd.none)
        _ -> (model, Cmd.none)
      Http.BadPayload err resp -> (model, Cmd.none)
      _ -> (model, Cmd.none)

    UpdateTextDifficultyOptions (Ok difficulties) ->
      ({ model | question_difficulties = difficulties }, Cmd.none)
    -- handle user-friendly msgs
    UpdateTextDifficultyOptions (Err _) ->
      (model, Cmd.none)

    UpdateQuizAttributes attr_name attr_value ->
      ({ model | quiz = Quiz.set_attributes model.quiz attr_name attr_value }, Cmd.none)

    ToggleEditable ((QuizField attrs) as quiz_field) editable ->
      ({ model | quiz_fields = update_quiz_field model.quiz_fields (update_editable quiz_field editable) }
      , selectAllInputText attrs.id)

post_quiz : CSRFToken -> Quiz -> Cmd Msg
post_quiz csrftoken quiz =
  let encoded_quiz = Quiz.Encode.quizEncoder quiz
      req =
    post_with_headers quiz_api_endpoint [Http.header "X-CSRFToken" csrftoken] (Http.jsonBody encoded_quiz)
    <| Text.Decode.textCreateRespDecoder
  in
    Http.send Submitted req

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = Text.Subscriptions.subscriptions TextComponentMsg
    , update = update
    }

view_msg : Maybe Text.Decode.TextCreateRespError -> Html Msg
view_msg msg = case msg of
  Just err -> Html.text <| toString err
  _ -> Html.text ""

view_success_msg : Maybe String -> Html Msg
view_success_msg msg = let msg_str = (case msg of
        Just str ->
          String.join " " [" ", str]
        _ -> "") in Html.text msg_str


view_submit : Model -> Html Msg
view_submit model = Html.div [classList [("submit_section", True)]] [
    Html.div [attribute "class" "submit", onClick SubmitQuiz] [
        Html.text "Save Quiz "
      , view_msg model.error_msg
      , view_success_msg model.success_msg
    ]
  , Html.div [attribute "class" "submit", onClick (TextComponentMsg Text.Update.AddText)] [
        Html.text "Add Text"
    ]
  ]

view_editable : Quiz -> QuizField -> Html Msg
view_editable quiz ((QuizField attrs) as field) =
  case attrs.editable of
    True -> attrs.edit quiz field
    _ -> attrs.view quiz field

view_quiz_title : Quiz -> QuizField -> Html Msg
view_quiz_title quiz quiz_field =
  let
    quiz_attrs = Quiz.attributes quiz
  in
    Html.div [
      onClick (ToggleEditable quiz_field True)
    , attribute "class" "editable"
    ] [
        Html.text "Quiz Title: "
      , Html.text quiz_attrs.title
      ]

edit_quiz_title : Quiz -> QuizField -> Html Msg
edit_quiz_title quiz ((QuizField field_attrs) as quiz_field) =
  let
    quiz_attrs = Quiz.attributes quiz
  in
    Html.input [
      attribute "type" "text"
    , attribute "value" quiz_attrs.title
    , attribute "id" field_attrs.id
    , onInput (UpdateQuizAttributes "title")
    , (onBlur (ToggleEditable quiz_field False)) ] [ ]


view_quiz : Model -> Html Msg
view_quiz model =
  div [attribute "class" "quiz_attributes"] [
    div [attribute "class" "quiz"] <| Array.toList <| Array.map (view_editable model.quiz) model.quiz_fields
  ]

view : Model -> Html Msg
view model = div [] [
      Views.view_header model.profile Nothing
    , (Views.view_preview)
    , (view_quiz model)
    , (Text.View.view_text_components TextComponentMsg (Quiz.text_components model.quiz) model.question_difficulties)
    , (view_submit model)
  ]
