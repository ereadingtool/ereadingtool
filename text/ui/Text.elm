module Text exposing (init, main, subscriptions, update, view)

import Dict exposing (Dict)
import Html exposing (Html, div)
import Menu.Items
import Ports
import Text.Resource

import TextReader.Model exposing (..)
import TextReader.Msg exposing (Msg(..))
import TextReader.Text.Model
import TextReader.TextWord
import TextReader.Update exposing (..)
import TextReader.View exposing (..)
import User.Profile
import User.Profile.TextReader.Flashcards
import Views

import Browser
import TextReader.WebSocket


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        profile =
            User.Profile.initProfile flags

        textReaderAddr =
            TextReader.WebSocket.toAddress flags.text_reader_ws_addr

        text_words_with_flashcards =
            List.map TextReader.TextWord.newFromParams flags.flashcards

        menuItems =
            Menu.Items.initMenuItems flags

        flashcards =
            User.Profile.TextReader.Flashcards.initFlashcards
                profile
                (Dict.fromList <|
                    List.map (\text_word -> ( TextReader.TextWord.phrase text_word, text_word )) text_words_with_flashcards
                )
    in
    ( { text = TextReader.Text.Model.emptyText
      , text_url = Text.Resource.TextReadingURL (Text.Resource.URL flags.text_url)
      , gloss = Dict.empty
      , profile = profile
      , menu_items = menuItems
      , flashcard = flashcards
      , progress = Init
      , flags = flags
      , exception = Nothing
      }
    , TextReader.WebSocket.connect textReaderAddr ""
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    TextReader.WebSocket.listen


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        sendCommand =
            \cmdRequest ->
                TextReader.WebSocket.sendCommand cmdRequest
    in
    case msg of
        Gloss reader_word ->
            ( { model | gloss = TextReader.Model.gloss reader_word Dict.empty }, Cmd.none )

        UnGloss reader_word ->
            ( { model | gloss = TextReader.Model.ungloss reader_word model.gloss }, Cmd.none )

        ToggleGloss reader_word ->
            ( { model | gloss = TextReader.Model.toggleGloss reader_word model.gloss }, Cmd.none )

        AddToFlashcards reader_word ->
            ( model, sendCommand <| AddToFlashcardsReq reader_word )

        RemoveFromFlashcards reader_word ->
            ( model, sendCommand <| RemoveFromFlashcardsReq reader_word )

        Select text_answer ->
            ( model, sendCommand <| AnswerReq text_answer )

        ViewFeedback _ _ _ _ ->
            ( model, Cmd.none )

        StartOver ->
            ( model, Ports.redirect (Text.Resource.textReadingURLToString model.text_url) )

        NextSection ->
            ( model, sendCommand NextReq )

        PrevSection ->
            ( model, sendCommand PrevReq )

        WebSocketResp str ->
            TextReader.Update.handleWSResp model str

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
        , TextReader.View.view_content model
        , Views.view_footer
        ]
