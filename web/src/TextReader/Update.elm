module TextReader.Update exposing (DeleteMe)

import Json.Decode
import TextReader.Decode
import TextReader.Model exposing (CmdReq(..), CmdResp(..), Model, Progress(..))
import TextReader.Msg exposing (Msg(..))
import User.Profile.TextReader.Flashcards


type DeleteMe
    = DeleteMe


routeCmdResp : Model -> CmdResp -> ( Model, Cmd Msg )
routeCmdResp model cmd_resp =
    case cmd_resp of
        StartResp text ->
            ( { model | text = text, exception = Nothing, progress = ViewIntro }, Cmd.none )

        InProgressResp section ->
            ( { model | exception = Nothing, progress = ViewSection section }, Cmd.none )

        CompleteResp text_scores ->
            ( { model | exception = Nothing, progress = Complete text_scores }, Cmd.none )

        AddToFlashcardsResp text_word ->
            ( { model | flashcard = User.Profile.TextReader.Flashcards.addFlashcard model.flashcard text_word }, Cmd.none )

        RemoveFromFlashcardsResp text_word ->
            ( { model | flashcard = User.Profile.TextReader.Flashcards.removeFlashcard model.flashcard text_word }, Cmd.none )

        ExceptionResp exception ->
            ( { model | exception = Just exception }, Cmd.none )


handleWSResp : Model -> String -> ( Model, Cmd Msg )
handleWSResp model str =
    case Json.Decode.decodeString TextReader.Decode.wsRespDecoder str of
        Ok cmd_resp ->
            routeCmdResp model cmd_resp

        Err err ->
            let
                _ =
                    Debug.log "websocket decode error" err
            in
            ( model, Cmd.none )
