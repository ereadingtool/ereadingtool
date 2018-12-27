module Text.Translations.Update exposing (..)

import Text.Model

import Text.Translations.Model exposing (..)
import Text.Translations.Msg exposing (..)

import Text.Encode
import Text.Decode

import Config

import Array exposing (Array)
import Dict

import Http

import HttpHelpers

import Flags


update : (Msg -> msg) -> Msg -> Model -> (Model, Cmd msg)
update parent_msg msg model =
  case msg of
    MatchTranslations word_instance ->
      let
        text_word = word_instance.text_word
        word = String.toLower text_word.word
      in
        case text_word.translations of
          Just new_translations ->
            let
              put_translations = putTranslations parent_msg model.flags.csrftoken new_translations
            in
              case Text.Translations.Model.getTextWords model word of
                Just text_words ->
                  (model, put_translations (Array.toList text_words))

                Nothing ->
                  (model, Cmd.none)

          Nothing ->
            (model, Cmd.none)

    UpdatedTextWords (Ok text_words) ->
      (Text.Translations.Model.setTextWords model text_words, Cmd.none)

    EditWord word_instance ->
      (Text.Translations.Model.editWord model word_instance, Cmd.none)

    CloseEditWord word_instance ->
      (Text.Translations.Model.uneditWord model word_instance, Cmd.none)

    MakeCorrectForContext translation ->
      (model, updateTranslationAsCorrect parent_msg model.flags.csrftoken translation)

    UpdateTextTranslation (Ok (word, instance, translation)) ->
      (Text.Translations.Model.updateTextTranslation model instance word translation, Cmd.none)

    UpdatedTextWords (Err err) -> let _ = Debug.log ("error updating text word" ++ toString err) in
      (model, Cmd.none)

    -- handle user-friendly msgs
    UpdateTextTranslation (Err err) -> let _ = Debug.log "error decoding text translation" err in
      (model, Cmd.none)

    UpdateTextTranslations (Ok words) -> let _ = Debug.log "words" (Dict.keys words) in
      ({ model | words = words }, Cmd.none)

    -- handle user-friendly msgs
    UpdateTextTranslations (Err err) -> let _ = Debug.log "error decoding text translations" err in
      (model, Cmd.none)

    UpdateNewTranslationForTextWord text_word translation_text ->
      (Text.Translations.Model.updateTranslationsForWord model text_word translation_text, Cmd.none)

    SubmitNewTranslationForTextWord text_word ->
      case Text.Translations.Model.getNewTranslationForWord model text_word of
        Just translation_text ->
          (model, postTranslation parent_msg model.flags.csrftoken text_word translation_text)

        Nothing ->
          (model, Cmd.none)

    SubmittedTextTranslation (Ok (word, instance, translation)) ->
      (Text.Translations.Model.addTextTranslation model instance word translation, Cmd.none)

    -- handle user-friendly msgs
    SubmittedTextTranslation (Err err) -> let _ = Debug.log "error decoding adding text translations" err in
      (model, Cmd.none)

    DeleteTranslation text_word text_translation ->
      (model, deleteTranslation parent_msg model.flags.csrftoken text_word text_translation)

    DeletedTranslation (Ok translation_deleted_resp) ->
      let
        _ = Debug.log "translation_deleted_resp" translation_deleted_resp
        _ = Debug.log "model words" model.words
        instance = translation_deleted_resp.instance
        word = translation_deleted_resp.word
        translation = translation_deleted_resp.translation
      in
        (Text.Translations.Model.removeTextTranslation model instance word translation, Cmd.none)

    -- handle user-friendly msgs
    DeletedTranslation (Err err) -> let _ = Debug.log "error decoding deleting text translations" err in
      (model, Cmd.none)

deleteTranslation : (Msg -> msg) -> Flags.CSRFToken -> Text.Model.TextWord -> Text.Model.TextWordTranslation -> Cmd msg
deleteTranslation msg csrftoken text_word translation =
  let
    endpoint_uri = Config.text_word_api_endpoint text_word.id
    headers = [Http.header "X-CSRFToken" csrftoken]
    encoded_translation = Text.Encode.deleteTextTranslationEncode translation.id
    body = (Http.jsonBody encoded_translation)
    request =
      HttpHelpers.delete_with_headers endpoint_uri headers body Text.Decode.textTranslationRemoveRespDecoder
  in
    Http.send (msg << DeletedTranslation) request

putTranslations :
  (Msg -> msg) -> Flags.CSRFToken -> List Text.Model.TextWordTranslation -> List Text.Model.TextWord -> Cmd msg
putTranslations msg csrftoken translations text_words =
  let
    endpoint_uri = Config.text_translation_api_merge_endpoint
    headers = [Http.header "X-CSRFToken" csrftoken]
    encoded_merge_request = Text.Encode.textTranslationsMergeEncoder translations text_words
    body = (Http.jsonBody encoded_merge_request)
    request =
      HttpHelpers.put_with_headers endpoint_uri headers body Text.Decode.textWordsDecoder
  in
    Http.send (msg << UpdatedTextWords) request

postTranslation : (Msg -> msg) -> Flags.CSRFToken -> Text.Model.TextWord -> String -> Cmd msg
postTranslation msg csrftoken text_word translation_text =
  let
    endpoint_uri = Config.text_word_api_endpoint text_word.id
    headers = [Http.header "X-CSRFToken" csrftoken]
    encoded_translation = Text.Encode.newTextTranslationEncoder translation_text
    body = (Http.jsonBody encoded_translation)
    request =
      HttpHelpers.post_with_headers endpoint_uri headers body Text.Decode.textTranslationAddRespDecoder
  in
    Http.send (msg << SubmittedTextTranslation) request

updateTranslationAsCorrect : (Msg -> msg) -> Flags.CSRFToken -> Text.Model.TextWordTranslation -> Cmd msg
updateTranslationAsCorrect msg csrftoken translation =
  let
    endpoint_uri = Config.text_translation_api_endpoint translation.id
    headers = [Http.header "X-CSRFToken" csrftoken]
    encoded_translation = Text.Encode.textTranslationAsCorrectEncoder { translation | correct_for_context = True }
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