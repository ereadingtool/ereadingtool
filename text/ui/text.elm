module Text exposing (init, main, subscriptions, update, view)

import Dict exposing (Dict)
import Html exposing (Html, div)
import Menu.Items
import Ports
import Text.Resource
import TextReader
import TextReader.Encode
import TextReader.Model exposing (..)
import TextReader.Msg exposing (Msg(..))
import TextReader.Text.Model
import TextReader.TextWord
import TextReader.Update exposing (..)
import TextReader.View exposing (..)
import User.Profile
import User.Profile.TextReader.Flashcards
import Views


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        profile =
            User.Profile.initProfile flags

        text_words_with_flashcards =
            List.map TextReader.TextWord.newFromParams flags.flashcards

        menu_items =
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
      , menu_items = menu_items
      , text_reader_ws_addr = TextReader.WebSocketAddress flags.text_reader_ws_addr
      , flashcard = flashcards
      , progress = Init
      , flags = flags
      , exception = Nothing
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen (TextReader.webSocketAddrToString model.text_reader_ws_addr) WebSocketResp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        send_command =
            \cmd ->
                WebSocket.send
                    (TextReader.webSocketAddrToString model.text_reader_ws_addr)
                    (TextReader.Encode.jsonToString <| TextReader.Encode.send_command cmd)
    in
    case msg of
        Gloss reader_word ->
            ( { model | gloss = TextReader.Model.gloss reader_word Dict.empty }, Cmd.none )

        UnGloss reader_word ->
            ( { model | gloss = TextReader.Model.ungloss reader_word model.gloss }, Cmd.none )

        ToggleGloss reader_word ->
            ( { model | gloss = TextReader.Model.toggleGloss reader_word model.gloss }, Cmd.none )

        AddToFlashcards reader_word ->
            ( model, send_command <| AddToFlashcardsReq reader_word )

        RemoveFromFlashcards reader_word ->
            ( model, send_command <| RemoveFromFlashcardsReq reader_word )

        Select text_answer ->
            ( model, send_command <| AnswerReq text_answer )

        ViewFeedback text_section text_question text_answer view_feedback ->
            ( model, Cmd.none )

        StartOver ->
            ( model, Ports.redirect (Text.Resource.textReadingURLToString model.text_url) )

        NextSection ->
            ( model, send_command NextReq )

        PrevSection ->
            ( model, send_command PrevReq )

        WebSocketResp str ->
            TextReader.Update.handle_ws_resp model str

        LogOut _ ->
            ( model, User.Profile.logout model.profile model.flags.csrftoken LoggedOut )

        LoggedOut (Ok logout_resp) ->
            ( model, Ports.redirect logout_resp.redirect )

        LoggedOut (Err _) ->
            ( model, Cmd.none )


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
view model =
    div []
        [ Views.view_authed_header model.profile model.menu_items LogOut
        , TextReader.View.view_content model
        , Views.view_footer
        ]
