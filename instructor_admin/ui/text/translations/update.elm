module Text.Translations.Update exposing (..)

import Dict exposing (Dict)

import Text.Model

import Text.Translations.Model exposing (..)
import Text.Translations.Msg exposing (..)

import Text.Encode
import Text.Decode

import Config

import Http

import HttpHelpers

import Flags


update : (Msg -> msg) -> Msg -> Model -> (Model, Cmd msg)
update parent_msg msg model =
  case msg of
    ShowLetter letter ->
      ({ model | current_letter = Just letter }, Cmd.none)

    MakeCorrectForContext translation ->
      (model, updateTranslationAsCorrect parent_msg model.flags.csrftoken translation)

    UpdateTextTranslation (Ok (word, translation)) ->
      let
        letter_group = Maybe.withDefault Dict.empty (Dict.get (String.toLower word) model.words)

        update_word =
          (\value ->
            case value of
              Just v ->
                case v.translations of
                  Just translations ->
                    Just ({ v | translations = Just (updateTranslation translations translation) })

                  -- word has no translations
                  Nothing -> value

              -- word not found
              Nothing -> value)

        new_letter_group = Dict.update word update_word letter_group

        update_word_group =
          (\value ->
            case value of
              Just v ->
                Just new_letter_group

              -- word group not found
              Nothing ->
                value)

        new_words = Dict.update (String.toLower word) update_word_group model.words
      in
        ({ model | words = new_words }, Cmd.none)

    -- handle user-friendly msgs
    UpdateTextTranslation (Err err) -> let _ = Debug.log "error decoding text translation" err in
      (model, Cmd.none)

    UpdateTextTranslations (Ok translations) ->
      ({ model | words = translations}, Cmd.none)

    -- handle user-friendly msgs
    UpdateTextTranslations (Err err) -> let _ = Debug.log "error decoding text translations" err in
      (model, Cmd.none)


updateTranslation :
     List Text.Model.TextWordTranslation
  -> Text.Model.TextWordTranslation
  -> List Text.Model.TextWordTranslation
updateTranslation translations translation =
  let
    update = (\tr -> if tr.id == translation.id then translation else tr)
  in
    List.map update translations

updateTranslationAsCorrect : (Msg -> msg) -> Flags.CSRFToken -> Text.Model.TextWordTranslation -> Cmd msg
updateTranslationAsCorrect msg csrftoken translation =
  let
    endpoint_uri = Config.text_translation_api_endpoint translation.id
    headers = [Http.header "X-CSRFToken" csrftoken]
    encoded_translation = Text.Encode.textTranslationEncoder translation
    body = (Http.jsonBody encoded_translation)
    request =
      HttpHelpers.put_with_headers endpoint_uri headers body Text.Decode.textTranslationUpdateRespDecoder
  in
    Http.send (msg << UpdateTextTranslation) request

retrieveTextWords : (Msg -> msg) -> Int -> Cmd msg
retrieveTextWords msg text_id =
  let
    request =
      Http.get (String.join "?" [String.join "" [Config.text_api_endpoint,  toString text_id], "text_words=list"])
        Text.Decode.textTranslationsDecoder
  in
    Http.send (msg << UpdateTextTranslations) request