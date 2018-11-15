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
        letter = String.left 1 (String.toUpper word)
        letter_group = Maybe.withDefault Dict.empty (Dict.get letter model.words)

        update_word =
          (\value ->
            case value of
              Just v ->
                let
                  text_word = setNoTRCorrectForContext v
                in
                  case text_word.translations of
                    Just translations ->
                      Just
                        { text_word | translations = Just (updateTranslation translations translation) }

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

        new_words = Dict.update letter update_word_group model.words
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

    UpdateNewTranslationForTextWord text_word translation_text ->
      ({ model | new_translations = Dict.insert text_word.word translation_text model.new_translations}, Cmd.none)

    AddNewTranslationForTextWord text_word ->
      case Dict.get text_word.word model.new_translations of
        Just translation_text ->
          (model, postTranslation parent_msg model.flags.csrftoken text_word translation_text)

        Nothing ->
          (model, Cmd.none)

    AddedTextTranslation (Ok (word, translation)) ->
      let
        letter = String.left 1 (String.toUpper word)
        letter_group = Maybe.withDefault Dict.empty (Dict.get letter model.words)
      in
        case Dict.get word letter_group of
          Just text_word ->
            let
              new_text_word = addTranslation text_word translation
              new_letter_group = Dict.insert word new_text_word letter_group
              new_words = Dict.insert letter new_letter_group model.words
            in
              ({ model | words = new_words }, Cmd.none)

          Nothing ->
            (model, Cmd.none)

    -- handle user-friendly msgs
    AddedTextTranslation (Err err) -> let _ = Debug.log "error decoding adding text translations" err in
      (model, Cmd.none)

    DeleteTranslation text_word text_translation ->
      (model, Cmd.none)

    DeletedTranslation (Ok (word, translation)) ->
      (model, Cmd.none)

    -- handle user-friendly msgs
    DeletedTranslation (Err err) -> let _ = Debug.log "error decoding deleting text translations" err in
      (model, Cmd.none)



addTranslation : Text.Model.TextWord -> Text.Model.TextWordTranslation -> Text.Model.TextWord
addTranslation text_word translation =
  let
    new_translations =
      (case text_word.translations of
        Just translations ->
          Just (translations ++ [translation])

        Nothing ->
          Nothing)
  in
    { text_word | translations = new_translations }

setNoTRCorrectForContext : Text.Model.TextWord -> Text.Model.TextWord
setNoTRCorrectForContext text_word =
  case text_word.translations of
    Just translations ->
      let
        new_translations = List.map (\tr -> { tr | correct_for_context = False }) translations
      in
        { text_word | translations = Just new_translations }

    Nothing ->
      text_word

updateTranslation :
     List Text.Model.TextWordTranslation
  -> Text.Model.TextWordTranslation
  -> List Text.Model.TextWordTranslation
updateTranslation translations translation =
  let
    update = (\tr -> if tr.id == translation.id then translation else tr)
  in
    List.map update translations

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
    Http.send (msg << AddedTextTranslation) request

updateTranslationAsCorrect : (Msg -> msg) -> Flags.CSRFToken -> Text.Model.TextWordTranslation -> Cmd msg
updateTranslationAsCorrect msg csrftoken translation =
  let
    endpoint_uri = Config.text_translation_api_endpoint translation.id
    headers = [Http.header "X-CSRFToken" csrftoken]
    encoded_translation = Text.Encode.textTranslationEncoder { translation | correct_for_context = True }
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