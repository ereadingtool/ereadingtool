import Html exposing (Html, div)

import Views
import User.Profile

import Ports

import WebSocket

import Flashcard.Encode
import Flashcard.Model

import Flashcard.View exposing (..)
import Flashcard.Model exposing (..)
import Flashcard.Msg exposing (Msg(..))
import Flashcard.Update exposing (..)


init : Flags -> (Model, Cmd Msg)
init flags =
  let
    profile = User.Profile.init_profile flags
  in
    ({ exception=Nothing
     , flags=flags
     , profile=profile
     , mode=Nothing
     , session_state=Loading
     , connect=True
     , answer=""
     , selected_quality=Nothing
     } , Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  case model.connect of
    True ->
      WebSocket.listen model.flags.flashcard_ws_addr WebSocketResp

    False ->
      Sub.none

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
    send_command = (\cmd ->
      WebSocket.send
        model.flags.flashcard_ws_addr
        (Flashcard.Encode.jsonToString <| Flashcard.Encode.send_command cmd))
  in
    case msg of
      WebSocketResp str ->
        Flashcard.Update.handle_ws_resp model str

      SelectMode mode ->
        (model, send_command (ChooseModeReq mode))

      Start ->
        (model, send_command StartReq)

      ReviewAnswer ->
        (model, send_command ReviewAnswerReq)

      Prev ->
        (Flashcard.Model.setQuality model Nothing, send_command PrevReq)

      Next ->
        (Flashcard.Model.setQuality model Nothing, send_command NextReq)

      InputAnswer str ->
        ({ model | answer = str }, Cmd.none)

      SubmitAnswer ->
        (model, send_command (AnswerReq model.answer))

      RateQuality q ->
        (Flashcard.Model.setQuality model (Just q), send_command (RateQualityReq q))

      LogOut msg ->
        (model, User.Profile.logout model.profile model.flags.csrftoken LoggedOut)

      LoggedOut (Ok logout_resp) ->
        (model, Ports.redirect logout_resp.redirect)

      LoggedOut (Err err) ->
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
    (Views.view_authed_header model.profile Nothing LogOut)
  , (Flashcard.View.view_content model)
  , (Views.view_footer)
  ]
