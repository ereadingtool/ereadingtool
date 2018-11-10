module Text.Translations.Update exposing (..)

import Text.Model

import Text.Translations.Model exposing (..)
import Text.Translations.Msg exposing (..)

import Text.Decode

import Config exposing (text_api_endpoint)

import Http


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    ShowLetter letter ->
      ({ model | current_letter = Just letter }, Cmd.none)

    MakeCorrectForContext translation ->
      (model, updateTranslationAsCorrect translation)

    UpdateTextTranslations (Ok translations) ->
      ({ model | words = translations}, Cmd.none)

    -- handle user-friendly msgs
    UpdateTextTranslations (Err err) -> let _ = Debug.log "error decoding text translations" err in
      (model, Cmd.none)


updateTranslationAsCorrect : Text.Model.TextWordTranslation -> Cmd Msg
updateTranslationAsCorrect translation =
  Cmd.none

retrieveTextWords : (Msg -> msg) -> Int -> Cmd msg
retrieveTextWords msg text_id =
  let
    request =
      Http.get (String.join "?" [String.join "" [text_api_endpoint,  toString text_id], "text_words=list"])
        Text.Decode.textTranslationsDecoder
  in
    Http.send (msg << UpdateTextTranslations) request