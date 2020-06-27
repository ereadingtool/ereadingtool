module Flashcards exposing (init, main, subscriptions, update, view)

import Flashcard.Model exposing (..)
import Flashcard.Msg exposing (Msg(..))
import Flashcard.Update exposing (..)
import Flashcard.View exposing (..)

import Flashcard.WebSocket
import Html exposing (Html, div)
import Menu.Items
import Ports
import User.Profile
import Views
import Browser


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        profile =
            User.Profile.initProfile flags

        menu_items =
            Menu.Items.initMenuItems flags
    in
    ( { exception = Nothing
      , flags = flags
      , profile = profile
      , menu_items = menu_items
      , mode = Nothing
      , session_state = Loading
      , connect = True
      , answer = ""
      , selected_quality = Nothing
      }
    , Flashcard.WebSocket.connect flags.flashcard_ws_addr ""
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.connect of
        True ->
            Flashcard.WebSocket.wsReceive

        False ->
            Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        sendCommand = \cmdRequest -> Flashcard.WebSocket.sendCommand "flashcard" cmdRequest
    in
    case msg of
        WebSocketResp response ->
            case response of
                Ok websocketMsg ->
                    Flashcard.Update.handle_ws_resp model websocketMsg

                Err err ->
                    Flashcard.Update.webSocketError model "invalid websocket msg" err

        SelectMode mode ->
            ( model, sendCommand (ChooseModeReq mode) )

        Start ->
            ( model, sendCommand StartReq )

        ReviewAnswer ->
            ( model, sendCommand ReviewAnswerReq )

        Prev ->
            ( Flashcard.Model.setQuality model Nothing, sendCommand PrevReq )

        Next ->
            ( Flashcard.Model.setQuality model Nothing, sendCommand NextReq )

        InputAnswer str ->
            ( { model | answer = str }, Cmd.none )

        SubmitAnswer ->
            ( model, sendCommand (AnswerReq model.answer) )

        RateQuality q ->
            ( Flashcard.Model.setQuality model (Just q), sendCommand (RateQualityReq q) )

        LogOut _ ->
            ( model, User.Profile.logout model.profile model.flags.csrftoken LoggedOut )

        LoggedOut (Ok logout_resp) ->
            ( model, Ports.redirect logout_resp.redirect )

        LoggedOut (Err _) ->
            ( model, Cmd.none )


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , subscriptions = subscriptions
        , update = update
        }



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ Views.view_authed_header model.profile model.menu_items LogOut
        , Flashcard.View.view_content model
        , Views.view_footer
        ]
