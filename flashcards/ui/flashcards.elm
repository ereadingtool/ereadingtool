import Html exposing (Html, div)

import Views
import User.Profile

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
        (model, send_command PrevReq)

      Next ->
        (model, send_command NextReq)

      _ ->
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
