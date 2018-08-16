import Http exposing (..)

import Html exposing (Html, div)
import Task

import Array exposing (Array)
import Dict exposing (Dict)

import Text.Section.Model exposing (TextSection)
import Text.Model exposing (Text)

import Text.Decode

import Views
import Profile

import Config
import Flags exposing (CSRFToken)

import WebSocket

import Json.Encode
import Json.Decode

import Text.Model as Texts exposing (Text)

import TextReader exposing (TextItemAttributes, WebSocketAddress)
import TextReader.Question exposing (TextQuestion)
import TextReader.Answer exposing (TextAnswer)

import TextReader.View exposing (..)
import TextReader.Model exposing (..)
import TextReader.Msg exposing (Msg(..))
import TextReader.Update exposing (..)


init : Flags -> (Model, Cmd Msg)
init flags =
  let
    profile = Profile.init_profile flags
    new_flags = { flags | text_reader_ws_addr = (String.join "" [Config.text_reading_ws_address, flags.text_id]) }
  in
    ({ text=Texts.new_text
     , sections=Array.fromList []
     , gloss=Dict.empty
     , profile=profile
     , progress=Init
     , flags=new_flags
     } , Cmd.batch [start profile new_flags.text_reader_ws_addr])


subscriptions : Model -> Sub Msg
subscriptions model =
  WebSocket.listen model.flags.text_reader_ws_addr WebSocketResp


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
      Started started ->
        case started of
          True ->
            ({ model | progress=ViewIntro }, Cmd.none)

          False ->
            (model, Cmd.none)

      Gloss word ->
        ({ model | gloss = Dict.insert word True model.gloss }, Cmd.none)

      UnGloss word ->
        ({ model | gloss = Dict.remove word model.gloss }, Cmd.none)

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

      WebSocketResp str ->
        let
          decoder = Json.Decode.field "command" Json.Decode.string |> Json.Decode.andThen command_decoder
          result = Json.Decode.decodeString decoder str
        in
          case result of
            Ok cmd_resp ->
              route_cmd_resp model cmd_resp

            Err err -> let _ = Debug.log "err" err in
              (model, Cmd.none)


main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

-- VIEW
view : Model -> Html Msg
view model = div [] [
    (Views.view_header model.profile Nothing)
  , (Views.view_filter)
  , (TextReader.View.view_content model)
  , (Views.view_footer)
  ]
