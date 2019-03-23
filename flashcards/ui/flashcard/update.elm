module Flashcard.Update exposing (..)

import Json.Decode


import Flashcard.Model exposing (..)

import Flashcard.Decode

import Flashcard.Mode exposing (Mode)

import Flashcard.Msg exposing (Msg(..))


route_cmd_resp : Model -> Mode -> CmdResp -> (Model, Cmd Msg)
route_cmd_resp model mode cmd_resp =
  case cmd_resp of
    InitResp resp ->
      ({ model | exception=Nothing, session_state=Init resp }, Cmd.none)

    ChooseModeChoiceResp choices ->
      ({ model | mode=Just mode, session_state=ViewModeChoices choices }, Cmd.none)

    ReviewCardAndAnswerResp card ->
      ({ model | mode=Just mode, session_state=ReviewCardAndAnswer card }, Cmd.none)

    ReviewCardResp card ->
      ({ model | mode=Just mode, session_state=ReviewCard card }, Cmd.none)

    ReviewedCardResp card ->
      ({ model | mode=Just mode, session_state=ReviewedCard card }, Cmd.none)

    ExceptionResp exception ->
      ({ model | exception = Just exception }, Cmd.none)

handle_ws_resp : Model -> String -> (Model, Cmd Msg)
handle_ws_resp model str =
  case Json.Decode.decodeString Flashcard.Decode.ws_resp_decoder str of
    Ok (mode, cmd_resp) ->
      route_cmd_resp model mode cmd_resp

    Err err -> let _ = Debug.log "websocket decode error" (err ++ " while decoding " ++ str) in
      (model, Cmd.none)