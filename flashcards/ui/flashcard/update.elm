module Flashcard.Update exposing (..)

import Json.Decode


import Flashcard.Model exposing (..)

import Flashcard.Decode

import Flashcard.Msg exposing (Msg(..))


route_cmd_resp : Model -> CmdResp -> (Model, Cmd Msg)
route_cmd_resp model cmd_resp =
  case cmd_resp of
    InitResp _ ->
      ({ model | exception=Nothing, session=Init }, Cmd.none)

    ChooseModeChoice choices ->
      ({ model | session=ViewModeChoices choices }, Cmd.none)

    ExceptionResp exception ->
      ({ model | exception = Just exception }, Cmd.none)

handle_ws_resp : Model -> String -> (Model, Cmd Msg)
handle_ws_resp model str =
  case Json.Decode.decodeString Flashcard.Decode.ws_resp_decoder str of
    Ok cmd_resp ->
      route_cmd_resp model cmd_resp

    Err err -> let _ = Debug.log "websocket decode error" err in
      (model, Cmd.none)