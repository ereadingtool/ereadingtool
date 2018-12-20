module Text.Translations.Model exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)

import Text.Model
import Text.Word
import Text.Translations

import Flags


type alias Flags = { csrftoken : Flags.CSRFToken }

type alias Model = {
   words: Dict Text.Translations.Word (Array Text.Model.TextWord)
 , editing_words: Dict Text.Translations.Word Bool
 , text: Text.Model.Text
 , new_translations: Dict String String
 , flags: Flags }


init : Flags -> Text.Model.Text -> Model
init flags text = {
   words=Dict.empty
 , editing_words=Dict.empty
 , text=text
 , new_translations=Dict.empty
 , flags=flags }

editingWord : Model -> String -> Bool
editingWord model word =
  Dict.member (String.toLower word) model.editing_words

editWord : Model -> Text.Model.WordInstance -> Model
editWord model word =
 { model | editing_words = let _ = Debug.log "editing words" model.editing_words in
   Dict.insert word.id True (Dict.insert (String.toLower word.text_word.word) True model.editing_words) }

uneditWord : Model -> Text.Model.WordInstance -> Model
uneditWord model word = let _ = Debug.log "editing words" model.editing_words in
 { model | editing_words =
   Dict.remove word.id (Dict.remove (String.toLower word.text_word.word) model.editing_words) }

editingWordInstance : Model -> Text.Model.WordInstance -> Bool
editingWordInstance model word =
  Dict.member word.id model.editing_words

getTextWord : Model -> Int -> Text.Translations.Word -> Maybe Text.Model.TextWord
getTextWord model instance word =
  case Dict.get word model.words of
    Just text_words ->
      Array.get instance text_words

    -- word not found
    Nothing ->
      Nothing

setTextWord : Model -> Int -> Text.Translations.Word -> Text.Model.TextWord -> Model
setTextWord model instance word text_word =
  case Dict.get word model.words of
    Just text_words ->
      let
        new_text_words = Array.set instance text_word text_words
      in
        { model | words = Dict.insert word new_text_words model.words }
    -- word not found
    Nothing ->
      model

updateTextTranslation : Model -> Int -> Text.Translations.Word -> Text.Model.TextWordTranslation -> Model
updateTextTranslation model instance word translation =
  case getTextWord model instance word of
    Just text_word ->
      let
        new_text_word = Text.Word.updateTranslation (Text.Word.setNoTRCorrectForContext text_word) translation
      in
        setTextWord model instance word new_text_word

    -- text word not found
    Nothing ->
      model

getNewTranslationForWord : Model -> Text.Model.TextWord -> Maybe String
getNewTranslationForWord model text_word =
  Dict.get text_word.word model.new_translations

updateTranslationsForWord : Model -> Text.Model.TextWord -> String -> Model
updateTranslationsForWord model text_word translation_text =
  { model | new_translations = Dict.insert text_word.word translation_text model.new_translations }


addTextTranslation : Model -> Int -> Text.Translations.Word -> Text.Model.TextWordTranslation -> Model
addTextTranslation model instance word translation =
  case getTextWord model instance word of
    Just text_word ->
      let
        new_text_word = Text.Word.addTranslation text_word translation
      in
        setTextWord model instance word new_text_word

    Nothing ->
      model

removeTextTranslation : Model -> Int -> Text.Translations.Word -> Text.Model.TextWordTranslation -> Model
removeTextTranslation model instance word translation =
  case getTextWord model instance word of
    Just text_word ->
      let
        new_text_word = Text.Word.removeTranslation text_word translation
      in
        setTextWord model instance word new_text_word

    Nothing ->
      model