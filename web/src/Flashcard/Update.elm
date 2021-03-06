module Flashcard.Update exposing (handle_ws_resp, route_cmd_resp)

import Api
import Api.WebSocket as WebSocket
import Flashcard.Decode
import Flashcard.Mode exposing (Mode)
import Flashcard.Model exposing (CmdResp(..), Model, SessionState(..))
import Flashcard.Msg exposing (Msg(..))
import Json.Decode


type Not
    = Not


route_cmd_resp : Model -> Maybe Mode -> CmdResp -> ( Model, Cmd Msg )
route_cmd_resp orig_model mode cmd_resp =
    let
        model =
            Flashcard.Model.setMode orig_model mode
    in
    case cmd_resp of
        InitResp resp ->
            ( Flashcard.Model.setSessionState model (Init resp), Cmd.none )

        ChooseModeChoiceResp choices ->
            ( Flashcard.Model.setSessionState model (ViewModeChoices choices), Cmd.none )

        ReviewCardAndAnswerResp card ->
            ( Flashcard.Model.setSessionState model (ReviewCardAndAnswer card), Cmd.none )

        ReviewedCardAndAnsweredCorrectlyResp card ->
            ( Flashcard.Model.setSessionState model (ReviewedCardAndAnsweredCorrectly card), Cmd.none )

        ReviewedCardAndAnsweredIncorrectlyResp card ->
            ( Flashcard.Model.setSessionState model (ReviewedCardAndAnsweredIncorrectly card), Cmd.none )

        RatedCardResp card ->
            ( Flashcard.Model.setSessionState model (RatedCard card), Cmd.none )

        ReviewCardResp card ->
            ( Flashcard.Model.setSessionState model (ReviewCard card), Cmd.none )

        ReviewedCardResp card ->
            ( Flashcard.Model.setSessionState model (ReviewedCard card), Cmd.none )

        FinishedReviewResp ->
            ( Flashcard.Model.disconnect (Flashcard.Model.setSessionState model FinishedReview)
            , Api.websocketDisconnect "flashcard"
            )

        ExceptionResp exception ->
            ( Flashcard.Model.setException model (Just exception), Cmd.none )


handle_ws_resp : Model -> WebSocket.WebSocketMsg -> ( Model, Cmd Msg )
handle_ws_resp model websocket_resp =
    case websocket_resp of
        WebSocket.Data { data } ->
            decodeWebSocketResp model data

        WebSocket.Error { error } ->
            webSocketError model "websocket error" error


decodeWebSocketResp : Model -> String -> ( Model, Cmd Msg )
decodeWebSocketResp model str =
    case Json.Decode.decodeString Flashcard.Decode.ws_resp_decoder str of
        Ok ( mode, cmd_resp ) ->
            route_cmd_resp model mode cmd_resp

        Err err ->
            webSocketError model "websocket decode error" (Json.Decode.errorToString err ++ " while decoding " ++ str)


webSocketError : Model -> String -> String -> ( Model, Cmd Msg )
webSocketError model err_type_str err_str =
    let
        _ =
            Debug.log err_type_str err_str
    in
    ( model, Cmd.none )
