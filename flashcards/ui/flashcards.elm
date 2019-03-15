import Html exposing (Html, div)

import Dict exposing (Dict)

import Views
import User.Profile

import WebSocket

import Flashcard.Encode
import Flashcard.Text.Model

import Flashcard.View exposing (..)
import Flashcard.Model exposing (..)
import Flashcard.Msg exposing (Msg(..))
import Flashcard.Update exposing (..)

import Config


init : Flags -> (Model, Cmd Msg)
init flags =
  let
    profile = User.Profile.init_profile flags
  in
    ({ exception=Nothing
     } , Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  WebSocket.listen model.flags.text_reader_ws_addr WebSocketResp

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
    send_command = (\cmd ->
      WebSocket.send
        model.flags.flashcard_ws_addr
        (Flashcard.Encode.jsonToString <| Flashcard.Encode.send_command cmd))
  in
    case msg of
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
