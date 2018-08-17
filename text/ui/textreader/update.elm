module TextReader.Update exposing (..)

import Array exposing (Array)

import TextReader.Model exposing (..)
import TextReader exposing (TextItemAttributes, WebSocketAddress)

import TextReader.Encode
import TextReader.Decode

import TextReader.Question exposing (TextQuestion)

import TextReader.Msg exposing (Msg(..))

import Json.Encode
import Json.Decode

import WebSocket

import Profile

import Task


handle_ws_resp : Model -> String -> (Model, Cmd Msg)
handle_ws_resp model str =
  case Json.Decode.decodeString TextReader.Decode.ws_resp_decoder str of
    Ok cmd_resp ->
      route_cmd_resp model cmd_resp

    Err err -> let _ = Debug.log "websocket decode error" err in
      (model, Cmd.none)

msgToCmd : Msg -> Cmd Msg
msgToCmd msg =
  Task.perform (\_ -> msg) (Task.succeed Nothing)

route_cmd_resp : Model -> CmdResp -> (Model, Cmd Msg)
route_cmd_resp model cmd_resp =
  case cmd_resp of
    StartResp result ->
      let
        text_req =
          WebSocket.send model.flags.text_reader_ws_addr
            (TextReader.Encode.jsonToString <| TextReader.Encode.send_command TextReq)
      in
        case result of
          True ->
            -- next request the text details
            (model, text_req)
          False ->
            (model, Cmd.none)

    TextResp text ->
      ({ model | text = text, progress=ViewIntro }, Cmd.none)

    NextResp result ->
      case result of
        True ->
          (model, Cmd.batch [ msgToCmd NextSection ])
        False ->
          (model, Cmd.none)

    _ ->
      (model, Cmd.none)


start : Profile.Profile -> WebSocketAddress -> Cmd Msg
start profile web_socket_addr =
  case profile of
    Profile.Student profile ->
      WebSocket.send web_socket_addr (Json.Encode.encode 0 (TextReader.Encode.send_command StartReq))
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
