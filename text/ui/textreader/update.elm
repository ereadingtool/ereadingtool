module TextReader.Update exposing (..)

import Array exposing (Array)

import Text.Section.Model exposing (TextSection)

import TextReader.Model exposing (..)
import TextReader exposing (TextItemAttributes, WebSocketAddress)

import TextReader.Question exposing (TextQuestion)

import TextReader.Msg exposing (Msg(..))

import Json.Encode
import Json.Decode

import WebSocket

import Profile

import Html exposing (Html)
import Html.Attributes exposing (class, classList, attribute, property)

import Task


route_cmd_resp : Model -> CmdResp -> (Model, Cmd Msg)
route_cmd_resp model cmd_resp =
  case cmd_resp of
    StartResp result ->
      let
        start_task = Task.succeed (Started result)
        msg = Task.perform (\err -> Started err) (\result -> Started result) start_task
      in
        (model, msg)

    NextResp result ->
      let
        next_task = Task.succeed (NextSection result)
        msg = Task.perform (\err -> Started err) (\result -> Started result) next_task
      in
        case result of
          True ->
            (model, Cmd.none)
          False ->
            (model, Cmd.none)

startDecoder : String -> Json.Decode.Decoder CmdResp
startDecoder str =
  let
    decoder = Json.Decode.field "result" Json.Decode.bool
  in
    case Json.Decode.decodeString decoder str of
      Ok result ->
        StartResp result

      Err err ->
        StartResp False


nextDecoder : String -> Json.Decode.Decoder CmdResp
nextDecoder str =
  let
    decoder = Json.Decode.field "result" Json.Decode.bool
  in
    case Json.Decode.decodeString decoder str of
      Ok result ->
        NextResp result

      Err err ->
        NextResp False


command_decoder : String -> Json.Decode.Decoder CmdResp
command_decoder cmd_str =
  let
    result_decoder = Json.Decode.field "result" Json.Decode.bool
  in
    case cmd_str of
      "start" ->
        startDecoder
      "next" ->
        nextDecoder

send_command : Command -> Json.Encode.Value
send_command (Command cmd_req cmd_resp) =
  case cmd_req of
    StartReq ->
      Json.Encode.object [
        (Json.Encode.string "command", Json.Encode.string "start")
      ]

    NextReq ->
      Json.Encode.object [
        (Json.Encode.string "command", Json.Encode.string  "next")
      ]

    AnswerReq answer_id ->
      Json.Encode.object [
        (Json.Encode.string "command", Json.Encode.string "answer")
      , (Json.Encode.string "answer_id", Json.Encode.int answer_id)
      ]

    CurrentSectionReq ->
      Json.Encode.object [
        (Json.Encode.string "command", Json.Encode.string "current_section")
      ]


start : Profile.Profile -> WebSocketAddress -> Cmd Msg
start profile web_socket_addr =
  case profile of
    Profile.Student profile ->
      let
        student_username = Profile.studentUserName profile
        _ = Debug.log "username" student_username
      in
        WebSocket.send web_socket_addr (send_command (Command StartReq StartResp))
    _ ->
      Cmd.none

update_completed_section : Int -> Int -> Array Section -> Cmd Msg
update_completed_section section_id section_index sections =
  Cmd.none

text_section : Array Section -> TextQuestion -> Maybe Section
text_section text_sections text_question =
  let
    text_section_index = TextReader.Question.text_section_index text_question
  in
    Array.get text_section_index text_sections

gen_text_sections : Int -> TextSection -> Section
gen_text_sections index text_section =
  Section
    text_section {index=index} (Array.indexedMap (TextReader.Question.gen_text_question index) text_section.questions)

clear_question_answers : Section -> Section
clear_question_answers section =
  let
    new_questions = Array.map (\question -> TextReader.Question.deselect_all_answers question) (questions section)
  in
    set_questions section new_questions

questions : Section -> Array TextQuestion
questions (Section section attrs questions) = questions

complete : Section -> Bool
complete section =
     List.all (\answered -> answered)
  <| Array.toList
  <| Array.map (\question -> TextReader.Question.answered question) (questions section)

completed_sections : Array Section -> Int
completed_sections sections =
     List.sum
  <| Array.toList
  <| Array.map (\section -> if (complete section) then 1 else 0) sections

max_score : Section -> Int
max_score section =
     List.sum
  <| Array.toList
  <| Array.map (\question -> 1) (questions section)

score : Section -> Int
score section =
     List.sum
  <| Array.toList
  <| Array.map (\question ->
       if (Maybe.withDefault False (TextReader.Question.answered_correctly question)) then 1 else 0) (questions section)

set_questions : Section -> Array TextQuestion -> Section
set_questions (Section text attrs _) new_questions =
  Section text attrs new_questions

set_question : Section -> TextQuestion -> Section
set_question (Section text text_attr questions) new_text_question =
  let
    question_index = TextReader.Question.index new_text_question
  in
    Section text text_attr (Array.set question_index new_text_question questions)

set_text_section : Array Section -> Section -> Array Section
set_text_section text_sections ((Section _ attrs _) as text_section) =
  Array.set attrs.index text_section text_sections
