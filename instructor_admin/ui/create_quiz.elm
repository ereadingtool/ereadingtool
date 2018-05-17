import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Array exposing (Array)

import Http
import HttpHelpers exposing (post_with_headers)

import Config exposing (text_api_endpoint)
import Flags exposing (CSRFToken, Flags)

import Views
import Profile
import Debug
import Json.Decode as Decode

import Text.Model exposing (Text, TextDifficulty)
import Text.View
import Text.Update

import Text.Component exposing (TextComponent, TextField)
import Text.Component.Group exposing (TextComponentGroup)
import Text.Subscriptions

import Text.Encode
import Text.Decode

import Answer.Field exposing (AnswerField, AnswerFeedbackField)
import Question.Field exposing (QuestionField, update_question_field, add_new_question, delete_question)

type Field = Question QuestionField | Answer AnswerField | Text TextField

type Msg =
    UpdateTextDifficultyOptions (Result Http.Error (List TextDifficulty))
  | SubmitQuiz
  | Submitted (Result Http.Error Text.Decode.TextCreateResp)
  | TextComponentMsg Text.Update.Msg

type alias Model = {
    flags : Flags
  , profile : Profile.Profile
  , success_msg : Maybe String
  , error_msg : Maybe Text.Decode.TextCreateRespError
  , text_components : TextComponentGroup
  , question_difficulties : List TextDifficulty }

type alias Filter = List String

init : Flags -> (Model, Cmd Msg)
init flags = ({
        flags=flags
      , success_msg=Nothing
      , error_msg=Nothing
      , profile=Profile.init_profile flags
      , text_components=Text.Component.Group.new_group
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
      , post_quiz model.flags.csrftoken (Text.Component.Group.toQuiz model.text_components))

    Submitted (Ok text_create_resp) -> case text_create_resp.id of
       Just text_id -> ({ model
         | success_msg = Just <| String.join " " <| [" success!", toString text_id]}, Cmd.none)
       _ -> (model, Cmd.none)

    Submitted (Err err) -> case err of
      Http.BadStatus resp -> case (Text.Decode.decodeCreateRespErrors (Debug.log "errors" resp.body)) of
        Ok errors -> let
          _ = (Debug.log "displaying validations" errors)
          new_text_components = Text.Component.Group.update_errors model.text_components errors
        in ({ model | text_components = new_text_components }, Cmd.none)
        _ -> (model, Cmd.none)
      Http.BadPayload err resp -> (model, Cmd.none)
      _ -> (model, Cmd.none)

    UpdateTextDifficultyOptions (Ok difficulties) ->
      ({ model | question_difficulties = difficulties }, Cmd.none)
    -- handle user-friendly msgs
    UpdateTextDifficultyOptions (Err _) ->
      (model, Cmd.none)

post_quiz : CSRFToken -> Array Text -> Cmd Msg
post_quiz csrftoken texts =
  let encoded_texts = Text.Encode.textsEncoder texts
      req =
    post_with_headers text_api_endpoint [Http.header "X-CSRFToken" csrftoken] (Http.jsonBody encoded_texts)
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

view : Model -> Html Msg
view model = div [] [
      Views.view_header (Profile.view_profile_header model.profile)
    , (Views.view_preview)
    , (Text.View.view_text_components TextComponentMsg model.text_components model.question_difficulties)
    , (view_submit model)
  ]
