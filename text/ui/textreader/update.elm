module TextReader.Update exposing (..)

import TextReader.Model exposing (..)

import TextReader.Decode

import TextReader.Msg exposing (Msg(..))

import User.Profile exposing (Profile(..))

import Json.Decode


route_cmd_resp : Model -> CmdResp -> (Model, Cmd Msg)
route_cmd_resp model cmd_resp =
  case cmd_resp of
    StartResp text ->
      ({ model | text = text, exception=Nothing, progress=ViewIntro }, Cmd.none)

    InProgressResp section ->
      ({ model | exception=Nothing, progress=ViewSection section }, Cmd.none)

    CompleteResp text_scores ->
      ({ model | exception=Nothing, progress=Complete text_scores }, Cmd.none)

    AddToFlashcardsResp text_word ->
      ({ model | profile = User.Profile.addFlashcard model.profile text_word}, Cmd.none)

    RemoveFromFlashcardsResp text_word ->
      ({ model | profile = User.Profile.removeFlashcard model.profile text_word}, Cmd.none)

    ExceptionResp exception ->
      ({ model | exception = Just exception }, Cmd.none)

handle_ws_resp : Model -> String -> (Model, Cmd Msg)
handle_ws_resp model str =
  case Json.Decode.decodeString TextReader.Decode.ws_resp_decoder str of
    Ok cmd_resp ->
      route_cmd_resp model cmd_resp

    Err err -> let _ = Debug.log "websocket decode error" err in
      (model, Cmd.none)
