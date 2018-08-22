import Html exposing (Html, div)

import Dict exposing (Dict)

import Views
import Profile

import WebSocket

import TextReader.Encode
import TextReader.Text.Model

import TextReader.View exposing (..)
import TextReader.Model exposing (..)
import TextReader.Msg exposing (Msg(..))
import TextReader.Update exposing (..)

init : Flags -> (Model, Cmd Msg)
init flags =
  let
    profile = Profile.init_profile flags
  in
    ({ text=TextReader.Text.Model.emptyText
     , gloss=Dict.empty
     , profile=profile
     , progress=Init
     , flags=flags
     , exception=Nothing
     } , Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  WebSocket.listen model.flags.text_reader_ws_addr WebSocketResp

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
    send_command = (\cmd ->
      WebSocket.send
        model.flags.text_reader_ws_addr
        (TextReader.Encode.jsonToString <| TextReader.Encode.send_command cmd))
  in
    case msg of
      Gloss word ->
        ({ model | gloss = Dict.insert word True model.gloss }, Cmd.none)

      UnGloss word ->
        ({ model | gloss = Dict.remove word model.gloss }, Cmd.none)

      Select text_answer ->
        (model, send_command <| AnswerReq text_answer)

      ViewFeedback text_section text_question text_answer view_feedback ->
        (model, Cmd.none)

      StartOver ->
        (model, Cmd.none)

      NextSection ->
        (model, send_command NextReq)

      PrevSection ->
       (model, send_command PrevReq)

      WebSocketResp str ->
        TextReader.Update.handle_ws_resp model str


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
    (Views.view_header model.profile Nothing)
  , (Views.view_filter)
  , (TextReader.View.view_content model)
  , (Views.view_footer)
  ]
