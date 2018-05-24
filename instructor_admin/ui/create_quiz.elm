import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Http
import HttpHelpers exposing (post_with_headers, put_with_headers)

import Config exposing (text_api_endpoint, quiz_api_endpoint)
import Flags

import Quiz.Model
import Quiz.Component exposing (QuizComponent)
import Quiz.Encode

import Views
import Profile
import Debug
import Json.Decode as Decode
import Json.Encode

import Date.Utils
import Text.Model exposing (Text, TextDifficulty)
import Quiz.Model

import Navigation
import Quiz.Decode

import Time

import Field
import Text.View
import Text.Update

import Task

import Text.Subscriptions

import Ports exposing (selectAllInputText)

import Array exposing (Array)


type alias Flags = Flags.Flags { quiz: Maybe Json.Encode.Value }

type QuizDecode = Task String Quiz.Model.Quiz

type QuizField = QuizField (Field.FieldAttributes {
    name : String
  , view : QuizComponent -> QuizField -> Html Msg
  , edit : QuizComponent -> QuizField -> Html Msg })

new_quiz_field : Field.FieldAttributes {
    name : String
  , view : QuizComponent -> QuizField -> Html Msg
  , edit : QuizComponent -> QuizField -> Html Msg } -> QuizField
new_quiz_field attrs = QuizField attrs

update_quiz_field : Array QuizField -> QuizField -> Array QuizField
update_quiz_field quiz_fields ((QuizField attrs) as quiz_field) = Array.set attrs.index quiz_field quiz_fields

update_editable : QuizField -> Bool -> QuizField
update_editable (QuizField attrs) editable = QuizField { attrs | editable = editable }

type Msg =
    UpdateTextDifficultyOptions (Result Http.Error (List TextDifficulty))
  | SubmitQuiz
  | Submitted (Result Http.Error Quiz.Decode.QuizCreateResp)
  | Updated (Result Http.Error Quiz.Decode.QuizUpdateResp)
  | TextComponentMsg Text.Update.Msg
  | ToggleEditable QuizField Bool
  | UpdateQuizAttributes String String
  | QuizJSONDecode (Result String QuizComponent)
  | ClearMessages Time.Time

type alias Model = {
    flags : Flags
  , edit_mode : Bool
  , profile : Profile.Profile
  , success_msg : Maybe String
  , error_msg : Maybe String
  , quiz_component : QuizComponent
  , quiz_fields : Array QuizField
  , question_difficulties : List TextDifficulty }

type alias Filter = List String

init : Flags -> (Model, Cmd Msg)
init flags = ({
        flags=flags
      , edit_mode=False
      , success_msg=Nothing
      , error_msg=Nothing
      , profile=Profile.init_profile flags
      , quiz_component=Quiz.Component.emptyQuizComponent
      , quiz_fields=Array.fromList [
          (new_quiz_field {
            id="quiz_title"
          , editable=False
          , error=False
          , view=view_quiz_title
          , name="title"
          , edit=edit_quiz_title
          , index=0 })
        , (new_quiz_field {
            id="quiz_date"
          , editable=False
          , error=False
          , view=view_quiz_date
          , name="quiz_dates"
          , edit=view_quiz_date
          , index=1 })
      ]
      , question_difficulties=[]
  }, Cmd.batch [ retrieveTextDifficultyOptions, (quizJSONtoComponent flags.quiz) ])

textDifficultyDecoder : Decode.Decoder (List TextDifficulty)
textDifficultyDecoder = Decode.keyValuePairs Decode.string

quizJSONtoComponent : Maybe Json.Encode.Value -> Cmd Msg
quizJSONtoComponent quiz =
  case quiz of
      Just json -> Task.attempt QuizJSONDecode
        (case (Decode.decodeValue Quiz.Decode.quizDecoder json) of
           Ok quiz -> Task.succeed (Quiz.Component.init quiz)
           Err err -> Task.fail err)
      _ -> Cmd.none

retrieveTextDifficultyOptions : Cmd Msg
retrieveTextDifficultyOptions =
  let request = Http.get (String.join "?" [text_api_endpoint, "difficulties=list"]) textDifficultyDecoder
  in Http.send UpdateTextDifficultyOptions request

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
    TextComponentMsg msg ->
      (Text.Update.update msg model)

    SubmitQuiz ->
      ({ model | error_msg = Nothing, success_msg = Nothing }
      , let
          save_quiz = (case model.edit_mode of
            True -> update_quiz
            False -> post_quiz)
        in
          save_quiz model.flags.csrftoken (Quiz.Component.quiz model.quiz_component))

    QuizJSONDecode result ->
      case result of
        Ok quiz_component ->
          let
            quiz = Quiz.Component.quiz quiz_component
          in
            ({ model |
                 quiz_component = quiz_component
               , edit_mode=True
               , success_msg = (Just <| "editing '" ++ quiz.title ++ "' quiz")
             }, Quiz.Component.reinitialize_ck_editors quiz_component)
        Err err -> let _ = Debug.log "quiz decode error" err in
          ({ model |
              error_msg = (Just <| "Something went wrong loading the quiz from the server.")
            , success_msg = (Just <| "Editing a new quiz") }, Cmd.none)

    ClearMessages time ->
      ({ model | success_msg = Nothing }, Cmd.none)

    Submitted (Ok quiz_create_resp) ->
      let
         quiz = Quiz.Component.quiz model.quiz_component
      in
         ({ model |
             success_msg = Just <| String.join " " [" saved '" ++ quiz.title ++ "'"]
           , edit_mode=True }, Navigation.load quiz_create_resp.redirect)

    Updated (Ok quiz_update_resp) ->
      ({ model | success_msg = Just <| String.join " " [" updated", toString quiz_update_resp.id]}, Cmd.none)

    Submitted (Err err) ->
      case err of
        Http.BadStatus resp -> let _ = Debug.log "submit quiz bad status error" resp.body in
          case (Quiz.Decode.decodeRespErrors resp.body) of
            Ok errors ->
              ({ model | quiz_component = Quiz.Component.update_quiz_errors model.quiz_component errors }, Cmd.none)
            _ -> (model, Cmd.none)

        Http.BadPayload err resp -> let _ = Debug.log "submit quiz bad payload error" resp.body in
          (model, Cmd.none)

        _ -> (model, Cmd.none)

    Updated (Err err) ->
      case err of
        Http.BadStatus resp -> let _ = Debug.log "update error bad status" resp in
          case (Quiz.Decode.decodeRespErrors resp.body) of
            Ok errors ->
              ({ model | quiz_component = Quiz.Component.update_quiz_errors model.quiz_component errors }, Cmd.none)
            _ -> (model, Cmd.none)

        Http.BadPayload err resp -> let _ = Debug.log "update error bad payload" resp in
          (model, Cmd.none)

        _ -> (model, Cmd.none)

    UpdateTextDifficultyOptions (Ok difficulties) ->
      ({ model | question_difficulties = difficulties }, Cmd.none)

    -- handle user-friendly msgs
    UpdateTextDifficultyOptions (Err _) ->
      (model, Cmd.none)

    UpdateQuizAttributes attr_name attr_value ->
      ({ model | quiz_component = Quiz.Component.set_quiz_attribute model.quiz_component attr_name attr_value }, Cmd.none)

    ToggleEditable ((QuizField attrs) as quiz_field) editable ->
      ({ model | quiz_fields = update_quiz_field model.quiz_fields (update_editable quiz_field editable) }
      , selectAllInputText attrs.id)

post_quiz : Flags.CSRFToken -> Quiz.Model.Quiz -> Cmd Msg
post_quiz csrftoken quiz =
  let encoded_quiz = Quiz.Encode.quizEncoder quiz
      req =
    post_with_headers quiz_api_endpoint [Http.header "X-CSRFToken" csrftoken] (Http.jsonBody encoded_quiz)
    <| Quiz.Decode.quizCreateRespDecoder
  in
    Http.send Submitted req

update_quiz : Flags.CSRFToken -> Quiz.Model.Quiz -> Cmd Msg
update_quiz csrftoken quiz =
  case quiz.id of
    Just quiz_id ->
      let
        encoded_quiz = Quiz.Encode.quizEncoder quiz
        req = put_with_headers
          (String.join "" [quiz_api_endpoint, toString quiz_id, "/"]) [Http.header "X-CSRFToken" csrftoken]
          (Http.jsonBody encoded_quiz) <| Quiz.Decode.quizUpdateRespDecoder
      in
        Http.send Updated req
    _ -> Cmd.none

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [
      Text.Subscriptions.subscriptions TextComponentMsg model
    , (case model.success_msg of
        Just msg -> Time.every (Time.second * 3) ClearMessages
        _ -> Sub.none)
  ]

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

view_error_msg : Maybe Quiz.Decode.QuizRespError -> Html Msg
view_error_msg msg =
  case msg of
    Just err -> Html.text <| toString err
    _ -> Html.text ""

view_msg : Maybe String -> Html Msg
view_msg msg =
  let
    msg_str = (case msg of
      Just str -> String.join " " [" ", str]
      _ -> "")
  in
    Html.text msg_str

view_msgs : Model -> Html Msg
view_msgs model = div [attribute "class" "msgs"] [
    div [attribute "class" "error_msg" ] [ view_msg model.error_msg ]
  , div [attribute "class" "success_msg"] [ view_msg model.success_msg ]
  ]

view_submit : Model -> Html Msg
view_submit model = Html.div [classList [("submit_section", True)]] [
    Html.div [attribute "class" "submit", onClick SubmitQuiz] [
        Html.text "Save Quiz "
      , (view_msgs model)
    ]
  , Html.div [attribute "class" "submit", onClick (TextComponentMsg Text.Update.AddText)] [
        Html.text "Add Text"
    ]
  ]

view_editable : QuizComponent -> QuizField -> Html Msg
view_editable quiz_component ((QuizField attrs) as field) =
  case attrs.editable of
    True -> attrs.edit quiz_component field
    _ -> attrs.view quiz_component field

view_quiz_date : QuizComponent -> QuizField -> Html Msg
view_quiz_date quiz_component quiz_field =
  let
    quiz = Quiz.Component.quiz quiz_component
  in
    Html.div [attribute "class" "quiz_dates"] <|
        (case quiz.modified_dt of
           Just modified_dt -> [ span [] [ Html.text ("Last Modified: " ++ Date.Utils.month_day_year_fmt modified_dt) ]]
           _ -> []) ++
        (case quiz.created_dt of
           Just created_dt -> [ span [] [ Html.text ("Created: " ++ Date.Utils.month_day_year_fmt created_dt) ] ]
           _ -> [])

view_quiz_title : QuizComponent -> QuizField -> Html Msg
view_quiz_title quiz_component quiz_field =
  let
    quiz = Quiz.Component.quiz quiz_component
  in
    Html.div [
      onClick (ToggleEditable quiz_field True)
    , attribute "class" "editable"
    ] [
        Html.text "Quiz Title: "
      , Html.text quiz.title
      ]

edit_quiz_title : QuizComponent -> QuizField -> Html Msg
edit_quiz_title quiz_component ((QuizField field_attrs) as quiz_field) =
  let
    quiz = Quiz.Component.quiz quiz_component
  in
    Html.input [
      attribute "type" "text"
    , attribute "value" quiz.title
    , attribute "id" field_attrs.id
    , onInput (UpdateQuizAttributes "title")
    , (onBlur (ToggleEditable quiz_field False)) ] [ ]


view_quiz : Model -> Html Msg
view_quiz model =
  div [attribute "class" "quiz_attributes"] [
       div [attribute "class" "quiz"]
    <| Array.toList
    <| Array.map (view_editable model.quiz_component) model.quiz_fields
  ]

view : Model -> Html Msg
view model = div [] [
      Views.view_header model.profile Nothing
    , (Views.view_preview)
    , (view_quiz model)
    , (Text.View.view_text_components TextComponentMsg (Quiz.Component.text_components model.quiz_component) model.question_difficulties)
    , (view_submit model)
  ]
