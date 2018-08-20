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


route_cmd_resp : Model -> CmdResp -> (Model, Cmd Msg)
route_cmd_resp model cmd_resp =
  case cmd_resp of
    StartResp text ->
      ({ model | text = text, progress=ViewIntro }, Cmd.none)

    NextResp text_section ->
      ({ model | progress=ViewSection (newSection text_section) }, Cmd.none)

    CompleteResp ->
      (model, Cmd.none)

handle_ws_resp : Model -> String -> (Model, Cmd Msg)
handle_ws_resp model str =
  case Json.Decode.decodeString TextReader.Decode.ws_resp_decoder str of
    Ok cmd_resp ->
      route_cmd_resp model cmd_resp

    Err err -> let _ = Debug.log "websocket decode error" err in
      (model, Cmd.none)

start : Profile.Profile -> WebSocketAddress -> Cmd Msg
start profile web_socket_addr =
  case profile of
    Profile.Student profile ->
      WebSocket.send web_socket_addr (Json.Encode.encode 0 (TextReader.Encode.send_command StartReq))
    _ ->
      Cmd.none

questions : Section -> Array TextQuestion
questions (Section section questions) = questions

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
