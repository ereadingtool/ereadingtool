module Text.Translations.Model exposing (..)

import Dict exposing (Dict)

import Text.Model
import Text.Translations

import Flags


type alias Flags = { csrftoken : Flags.CSRFToken }

type alias Model = {
   words: Dict Text.Translations.Word Text.Model.TextWord
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
 { model | editing_words =
   Dict.insert word.id True (Dict.insert (String.toLower word.text_word.word) True model.editing_words) }

uneditWord : Model -> Text.Model.WordInstance -> Model
uneditWord model word =
 { model | editing_words =
   Dict.remove word.id (Dict.remove (String.toLower word.text_word.word) model.editing_words) }

editingWordInstance : Model -> Text.Model.WordInstance -> Bool
editingWordInstance model word =
  Dict.member word.id model.editing_words

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

updateTextTranslation : Model -> Text.Translations.Word -> Text.Model.TextWordTranslation -> Model
updateTextTranslation model word translation =
  let
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
      in
        { model | words = Dict.update word update_word model.words }

getNewTranslationForWord : Model -> Text.Model.TextWord -> Maybe String
getNewTranslationForWord model text_word =
  Dict.get text_word.word model.new_translations

updateTranslationsForWord : Model -> Text.Model.TextWord -> String -> Model
updateTranslationsForWord model text_word translation_text =
  { model | new_translations = Dict.insert text_word.word translation_text model.new_translations }

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

addTextTranslation : Model -> Text.Translations.Word -> Text.Model.TextWordTranslation -> Model
addTextTranslation model word translation =
  case Dict.get word model.words of
    Just text_word ->
      let
        new_text_word = addTranslation text_word translation
        new_words = Dict.insert word new_text_word model.words
      in
        { model | words = new_words }

    Nothing ->
      model

removeTranslation : Text.Model.TextWord -> Text.Model.TextWordTranslation -> Text.Model.TextWord
removeTranslation text_word translation =
  case text_word.translations of
    Just translations ->
      let
        new_translations = List.filter (\tr -> tr.id /= translation.id) translations
      in
        { text_word | translations = Just new_translations }

    Nothing ->
      text_word

removeTextTranslation : Model -> Text.Translations.Word -> Text.Model.TextWordTranslation -> Model
removeTextTranslation model word translation =
  case Dict.get word model.words of
      Just text_word ->
        let
          new_text_word = removeTranslation text_word translation
          new_words = Dict.insert word new_text_word model.words
        in
          { model | words = new_words }

      Nothing ->
        model