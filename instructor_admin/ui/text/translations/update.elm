module Text.Translations.Update exposing (..)

import Text.Translations.Model exposing (..)
import Text.Translations.Msg exposing (..)

import Text.Translations exposing (..)

import Text.Translations.Word.Instance exposing (WordInstance)
import Text.Translations.TextWord exposing (TextWord)

import Text.Translations.Encode
import Text.Translations.Word.Instance.Encode

import Text.Translations.Decode

import Config

import Dict exposing (Dict)
import Array exposing (Array)

import Http
import Task exposing (Task)

import HttpHelpers

import Flags


update : (Msg -> msg) -> Msg -> Model -> (Model, Cmd msg)
update parent_msg msg model =
  case msg of
    MatchTranslations word_instance ->
      (model, matchTranslations parent_msg model word_instance)

    UpdatedTextWords (Ok text_words) ->
      (Text.Translations.Model.setTextWords model text_words, Cmd.none)

    UpdatedTextWord (Ok text_word) ->
      (Text.Translations.Model.setTextWords model [text_word], Cmd.none)

    EditWord word_instance ->
      (Text.Translations.Model.editWord model word_instance, Cmd.none)

    CloseEditWord word_instance ->
      (Text.Translations.Model.uneditWord model word_instance, Cmd.none)

    MakeCorrectForContext translation ->
      (model, updateTranslationAsCorrect parent_msg model.flags.csrftoken translation)

    UpdateTextTranslation (Ok (word, instance, translation)) ->
      (Text.Translations.Model.updateTextTranslation model instance word translation, Cmd.none)

    UpdatedTextWords (Err err) -> let _ = Debug.log "error updating text words" err in
      (model, Cmd.none)

    UpdatedTextWord (Err err) -> let _ = Debug.log "error updating text word" err in
      (model, Cmd.none)

    MergeWords word_instances ->
      mergeWords parent_msg model model.flags.csrftoken word_instances

    MergedWords (Ok merge_resp) ->
      case merge_resp.grouped of
        True ->
          ( Text.Translations.Model.completeMerge
              model merge_resp.section merge_resp.phrase merge_resp.instance merge_resp.text_words
          , Cmd.none)

        False -> let _ = Debug.log "error merging text words" merge_resp.error in
          (Text.Translations.Model.cancelMerge model, Cmd.none)

    MergedWords (Err err) -> let _ = Debug.log "error merging text words" err in
      (model, Cmd.none)

    AddToMergeWords word_instance ->
      (Text.Translations.Model.addToMergeWords model word_instance, Cmd.none)

    RemoveFromMergeWords word_instance ->
      (Text.Translations.Model.removeFromMergeWords model word_instance, Cmd.none)

    DeleteTextWord text_word ->
      (model, Cmd.none)

    DeletedTextWord text_word ->
      (model, Cmd.none)

    -- handle user-friendly msgs
    UpdateTextTranslation (Err err) -> let _ = Debug.log "error decoding text translation" err in
      (model, Cmd.none)

    UpdateTextTranslations (Ok words) ->
      ({ model | words = words }, Cmd.none)

    -- handle user-friendly msgs
    UpdateTextTranslations (Err err) -> let _ = Debug.log "error decoding text translations" err in
      (model, Cmd.none)

    UpdateNewTranslationForTextWord text_word translation_text ->
      (Text.Translations.Model.updateTranslationsForWord model text_word translation_text, Cmd.none)

    AddTextWord word_instance ->
      (model, addAsTextWord parent_msg model model.flags.csrftoken word_instance)

    SubmitNewTranslationForTextWord text_word ->
      case Text.Translations.Model.getNewTranslationForWord model text_word of
        Just translation_text ->
          (model, postTranslation parent_msg model.flags.csrftoken text_word translation_text True)

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
        instance = translation_deleted_resp.instance
        word = translation_deleted_resp.word
        translation = translation_deleted_resp.translation
      in
        (Text.Translations.Model.removeTextTranslation model instance word translation, Cmd.none)

    -- handle user-friendly msgs
    DeletedTranslation (Err err) -> let _ = Debug.log "error deleting text translations" err in
      (model, Cmd.none)

    SelectGrammemeForEditing word_instance grammeme_name ->
      (Text.Translations.Model.selectGrammemeForEditing model grammeme_name, Cmd.none)

    InputGrammeme word_instance grammeme_value ->
      (Text.Translations.Model.inputGrammeme model grammeme_value, Cmd.none)

    SaveEditedGrammemes word_instance ->
      (model, updateGrammemes parent_msg model.flags.csrftoken word_instance model.editing_grammemes)

    RemoveGrammeme word_instance grammeme_str ->
      (model, Cmd.none)


mergeWords : (Msg -> msg) -> Model -> Flags.CSRFToken -> List WordInstance -> (Model, Cmd msg)
mergeWords parent_msg model csrftoken word_instances =
  case Text.Translations.Word.Instance.verifyCanMergeWords word_instances of
    True ->
      -- all word instances are ready to merge
      (model, postMergeWords parent_msg model model.flags.csrftoken word_instances)

    False ->
      -- lock editing on the page and instantiate some asynchronous tasks to associate text words with these
      -- word instances
      let
        word_instances_with_no_text_words =
          List.filter (Text.Translations.Word.Instance.hasTextWord >> not) word_instances
      in
        ({ model | edit_lock = True }
        , addTextWords parent_msg model model.flags.csrftoken word_instances)

addTextWords : (Msg -> msg) -> Model -> Flags.CSRFToken -> List WordInstance -> Cmd msg
addTextWords parent_msg model csrftoken word_instances =
  Task.attempt (UpdatedTextWords >> parent_msg)
  <| Task.sequence
  <| List.map Http.toTask
  <| List.map (addAsTextWordRequest model csrftoken) word_instances

addAsTextWordRequest : Model -> Flags.CSRFToken -> WordInstance -> Http.Request TextWord
addAsTextWordRequest model csrftoken word_instance =
  let
    endpoint_uri = (Text.Translations.addTextWordEndpointToString model.add_as_text_word_endpoint)
    headers = [Http.header "X-CSRFToken" csrftoken]
    encoded_text_word = Text.Translations.Word.Instance.Encode.textWordAddEncoder model.text_id word_instance
    body = (Http.jsonBody encoded_text_word)
  in
    HttpHelpers.post_with_headers endpoint_uri headers body Text.Translations.Decode.textWordInstanceDecoder

addAsTextWord : (Msg -> msg) -> Model -> Flags.CSRFToken -> WordInstance -> Cmd msg
addAsTextWord parent_msg model csrftoken word_instance =
  Http.send (parent_msg << (UpdatedTextWord)) (addAsTextWordRequest model csrftoken word_instance)

postMergeWords : (Msg -> msg) -> Model -> Flags.CSRFToken -> List WordInstance -> Cmd msg
postMergeWords parent_msg model csrftoken word_instances =
  let
    endpoint_url = (Text.Translations.mergeTextWordEndpointToString model.merge_textword_endpoint)
    headers = [Http.header "X-CSRFToken" csrftoken]
    text_words = List.filterMap (\instance -> (Text.Translations.Word.Instance.textWord instance)) word_instances
    encoded_text_word_ids = Text.Translations.Encode.textWordMergeEncoder text_words
    body = (Http.jsonBody encoded_text_word_ids)
    request =
      HttpHelpers.post_with_headers endpoint_url headers body Text.Translations.Decode.textWordMergeDecoder
  in
    Http.send (parent_msg << MergedWords) request

matchTranslations : (Msg -> msg) -> Model -> WordInstance -> Cmd msg
matchTranslations parent_msg model word_instance =
  let
    word = String.toLower (Text.Translations.Word.Instance.word word_instance)
  in
    case (Text.Translations.Word.Instance.textWord word_instance) of
      Just text_word ->
        case (Text.Translations.TextWord.translations text_word) of
          Just new_translations ->
            let
              match_translations = putMatchTranslations parent_msg model.flags.csrftoken
            in
              case Text.Translations.Model.getTextWords model word of
                Just text_words ->
                  match_translations new_translations (Array.toList text_words)

                -- no text words associated with this word
                Nothing ->
                  Cmd.none

          -- no translations to match
          Nothing ->
            Cmd.none

      -- no text word
      Nothing ->
        Cmd.none

deleteTranslation : (Msg -> msg) -> Flags.CSRFToken -> TextWord -> Translation -> Cmd msg
deleteTranslation msg csrftoken text_word translation =
  let
    headers = [Http.header "X-CSRFToken" csrftoken]
    encoded_translation = Text.Translations.Encode.deleteTextTranslationEncode translation.id
    body = Http.jsonBody encoded_translation
    request =
      HttpHelpers.delete_with_headers
        translation.endpoint headers body Text.Translations.Decode.textTranslationRemoveRespDecoder
  in
    Http.send (msg << DeletedTranslation) request

putMatchTranslations :
  (Msg -> msg) -> Flags.CSRFToken -> List Translation -> List TextWord -> Cmd msg
putMatchTranslations msg csrftoken translations text_words =
  let
    endpoint_uri = Config.text_translation_api_match_endpoint
    headers = [Http.header "X-CSRFToken" csrftoken]
    encoded_merge_request = Text.Translations.Encode.textTranslationsMergeEncoder translations text_words
    body = Http.jsonBody encoded_merge_request
    request =
      HttpHelpers.put_with_headers endpoint_uri headers body Text.Translations.Decode.textWordInstancesDecoder
  in
    Http.send (msg << UpdatedTextWords) request

updateGrammemes : (Msg -> msg) -> Flags.CSRFToken -> WordInstance -> Dict String String -> Cmd msg
updateGrammemes msg csrftoken word_instance grammemes =
  case Text.Translations.Word.Instance.textWord word_instance of
    Just text_word ->
      let
        headers = [Http.header "X-CSRFToken" csrftoken]

        text_word_endpoint = Text.Translations.TextWord.text_word_endpoint text_word

        encoded_grammemes =
          Text.Translations.Encode.grammemesEncoder text_word grammemes

        body = (Http.jsonBody encoded_grammemes)

        request =
          HttpHelpers.put_with_headers
            text_word_endpoint headers body Text.Translations.Decode.textWordInstanceDecoder
      in
        Http.send (msg << UpdatedTextWord) request

    -- no text word to update
    Nothing ->
      Cmd.none

postTranslation : (Msg -> msg) -> Flags.CSRFToken -> TextWord -> String -> Bool -> Cmd msg
postTranslation msg csrftoken text_word translation_text correct_for_context =
  let
    endpoint_uri = Text.Translations.TextWord.translations_endpoint text_word
    headers = [Http.header "X-CSRFToken" csrftoken]
    encoded_translation = Text.Translations.Encode.newTextTranslationEncoder translation_text correct_for_context
    body = Http.jsonBody encoded_translation

    request =
      HttpHelpers.post_with_headers endpoint_uri headers body Text.Translations.Decode.textTranslationAddRespDecoder
  in
    Http.send (msg << SubmittedTextTranslation) request

updateTranslationAsCorrect : (Msg -> msg) -> Flags.CSRFToken -> Translation -> Cmd msg
updateTranslationAsCorrect msg csrftoken translation =
  let
    headers = [Http.header "X-CSRFToken" csrftoken]

    encoded_translation =
      Text.Translations.Encode.textTranslationAsCorrectEncoder { translation | correct_for_context = True }

    body = (Http.jsonBody encoded_translation)

    request =
      HttpHelpers.put_with_headers
        translation.endpoint headers body Text.Translations.Decode.textTranslationUpdateRespDecoder
  in
    Http.send (msg << UpdateTextTranslation) request

retrieveTextWords : (Msg -> msg) -> Int -> Cmd msg
retrieveTextWords msg text_id =
  let
    request =
      Http.get (String.join "?" [String.join "" [Config.text_api_endpoint,  toString text_id, "/"], "text_words=list"])
        Text.Translations.Decode.textWordDictInstancesDecoder
  in
    Http.send (msg << UpdateTextTranslations) request