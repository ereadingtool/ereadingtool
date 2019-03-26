module Flashcard.Update exposing (..)

import Json.Decode


import Flashcard.Model exposing (..)

import Flashcard.Decode

import Flashcard.Mode exposing (Mode)

import Flashcard.Msg exposing (Msg(..))


route_cmd_resp : Model -> Mode -> CmdResp -> (Model, Cmd Msg)
route_cmd_resp orig_model mode cmd_resp =
  let
    model = Flashcard.Model.setMode orig_model (Just mode)
  in
    case cmd_resp of
      InitResp resp ->
        (Flashcard.Model.setSessionState model (Init resp), Cmd.none)

      ChooseModeChoiceResp choices ->
        (Flashcard.Model.setSessionState model (ViewModeChoices choices), Cmd.none)

      ReviewCardAndAnswerResp card ->
        (Flashcard.Model.setSessionState model (ReviewCardAndAnswer card), Cmd.none)

      ReviewCardResp card ->
        (Flashcard.Model.setSessionState model (ReviewCard card), Cmd.none)

      ReviewedCardResp card ->
        (Flashcard.Model.setSessionState model (ReviewedCard card), Cmd.none)

      FinishedReviewResp ->
        (Flashcard.Model.disconnect (Flashcard.Model.setSessionState model FinishedReview), Cmd.none)

      ExceptionResp exception ->
        (Flashcard.Model.setException model (Just exception), Cmd.none)

handle_ws_resp : Model -> String -> (Model, Cmd Msg)
handle_ws_resp model str =
  case Json.Decode.decodeString Flashcard.Decode.ws_resp_decoder str of
    Ok (mode, cmd_resp) ->
      route_cmd_resp model mode cmd_resp

    Err err -> let _ = Debug.log "websocket decode error" (err ++ " while decoding " ++ str) in
      (model, Cmd.none)