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
 , merging_words: Dict String Text.Model.WordInstance
 , editing_words: Dict Text.Translations.Word Int
 , editing_word_instances: Dict Text.Translations.Word Bool
 , text: Text.Model.Text
 , new_translations: Dict String String
 , flags: Flags }


init : Flags -> Text.Model.Text -> Model
init flags text = {
   words=Dict.empty
 , merging_words=Dict.empty
 , editing_words=Dict.empty
 , editing_word_instances=Dict.empty
 , text=text
 , new_translations=Dict.empty
 , flags=flags }


cancelMerge : Model -> Model
cancelMerge model =
  { model | merging_words = Dict.empty }

mergingWords : Model -> Dict String Text.Model.WordInstance
mergingWords model =
  model.merging_words

mergingWord : Model -> Text.Model.WordInstance -> Bool
mergingWord model word_instance =
  Dict.member word_instance.id model.merging_words

addToMergeWords : Model -> Text.Model.WordInstance -> Model
addToMergeWords model word_instance =
  { model | merging_words = Dict.insert word_instance.id word_instance model.merging_words }

removeFromMergeWords : Model -> Text.Model.WordInstance -> Model
removeFromMergeWords model word_instance =
  { model | merging_words = Dict.remove word_instance.id model.merging_words }

instanceCount : Model -> Text.Translations.Word -> Int
instanceCount model word =
  case getTextWords model word of
    Just text_words ->
      Array.length text_words

    Nothing ->
      0

getTextWords : Model -> Text.Translations.Word -> Maybe (Array Text.Model.TextWord)
getTextWords model word =
  Dict.get word model.words

editingWord : Model -> String -> Bool
editingWord model word =
  Dict.member (String.toLower word) model.editing_words

editWord : Model -> Text.Model.WordInstance -> Model
editWord model word_instance =
  let
    normalized_word = String.toLower word_instance.word

    new_edited_words =
      (case Dict.get normalized_word model.editing_words of
        Just ref_count ->
          Dict.insert normalized_word (ref_count+1) model.editing_words

        Nothing ->
          Dict.insert normalized_word 0 model.editing_words)

    new_editing_word_instances = Dict.insert word_instance.id True model.editing_word_instances
  in
    { model | editing_words = new_edited_words, editing_word_instances = new_editing_word_instances }

uneditWord : Model -> Text.Model.WordInstance -> Model
uneditWord model word_instance =
  let
    normalized_word = String.toLower word_instance.word

    new_edited_words =
      (case Dict.get normalized_word model.editing_words of
        Just ref_count ->
          if (ref_count - 1) == -1 then
            Dict.remove normalized_word model.editing_words
          else
            Dict.insert normalized_word (ref_count-1) model.editing_words

        Nothing ->
          model.editing_words)

    new_editing_word_instances = Dict.remove word_instance.id model.editing_word_instances
    cancelled_merge_model = cancelMerge model
  in
   { cancelled_merge_model |
     editing_words = new_edited_words
   , editing_word_instances = new_editing_word_instances }

editingWordInstance : Model -> Text.Model.WordInstance -> Bool
editingWordInstance model word_instance =
  Dict.member word_instance.id model.editing_word_instances

getTextWord : Model -> Int -> Text.Translations.Word -> Maybe Text.Model.TextWord
getTextWord model instance word =
  case getTextWords model word of
    Just text_words ->
      Array.get instance text_words

    -- word not found
    Nothing ->
      Nothing

setTextWords : Model -> List Text.Model.TextWord -> Model
setTextWords model text_words =
  case List.head text_words of
    Just first_text_word ->
      { model | words = Dict.insert (String.toLower first_text_word.word) (Array.fromList text_words) model.words }

    Nothing ->
      model

setTextWord : Model -> Int -> Text.Translations.Word -> Text.Model.TextWord -> Model
setTextWord model instance word text_word =
  case getTextWords model word of
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
  case getTextWord model instance (String.toLower word) of
    Just text_word ->
      let
        new_text_word = Text.Word.addTranslation text_word translation
      in
        setTextWord model instance word new_text_word

    Nothing ->
      model

removeTextTranslation : Model -> Int -> Text.Translations.Word -> Text.Model.TextWordTranslation -> Model
removeTextTranslation model instance word translation =
  case getTextWord model instance (String.toLower word) of
    Just text_word ->
      let
        new_text_word = Text.Word.removeTranslation text_word translation
      in
        setTextWord model instance word new_text_word

    Nothing ->
      model