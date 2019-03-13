module Text.Translations.TextWord exposing (..)

import Dict exposing (Dict)

import Text.Translations exposing (..)


type Word = SingleWord (Maybe TextGroupDetails) | CompoundWord

type alias Endpoints = {
    text_word: String
  , translations: String
  }

type TextWord = TextWord Int Instance Phrase (Maybe Grammemes) (Maybe Translations) Word Endpoints


grammemeValue : TextWord -> String -> Maybe String
grammemeValue text_word grammeme_name =
  case (grammemes text_word) of
    Just grammemes ->
      Dict.get grammeme_name grammemes

    Nothing ->
      Nothing

grammemes : TextWord -> Maybe Grammemes
grammemes (TextWord _ _ _ grammemes _ _ _) =
  grammemes

strToWordType : (String, Maybe TextGroupDetails) -> Word
strToWordType (str, group_details) =
  case str of
    "single" ->
      SingleWord group_details

    "compound" ->
      CompoundWord

    _ ->
      SingleWord group_details

wordTypeToString : Word -> String
wordTypeToString word =
  case word of
    SingleWord _ ->
      "single"

    CompoundWord ->
      "compound"

wordType : TextWord -> String
wordType text_word =
  wordTypeToString (word text_word)

word : TextWord -> Word
word (TextWord _ _ _ _ _ word _) =
  word

instance : TextWord -> Int
instance (TextWord _ instance _ _ _ _ _) =
  instance

wordTypeToGroup : Word -> Maybe TextGroupDetails
wordTypeToGroup word =
  case word of
    SingleWord group_details ->
      group_details

    CompoundWord ->
      Nothing

group : TextWord -> Maybe TextGroupDetails
group (TextWord _ _ _ _ _ word _) =
  wordTypeToGroup word

endpoints : TextWord -> Endpoints
endpoints (TextWord _ _ _ _ _ _ endpoints) =
  endpoints

translations_endpoint : TextWord -> String
translations_endpoint text_word =
  (endpoints text_word).translations

text_word_endpoint : TextWord -> String
text_word_endpoint text_word =
  (endpoints text_word).text_word

id : TextWord -> Int
id (TextWord id _ _ _ _ _ _) =
  id

new : Int -> Instance -> Phrase -> Maybe Grammemes -> Maybe Translations -> Word -> Endpoints -> TextWord
new id instance phrase grammemes translations word endpoint =
  TextWord id instance phrase grammemes translations word endpoint

phrase : TextWord -> Phrase
phrase (TextWord _ _ phrase _ _ _ _) =
  phrase

translations : TextWord -> Maybe Translations
translations (TextWord _ _ _ _ translations __ ) =
  translations

addTranslation : TextWord -> Translation -> TextWord
addTranslation (TextWord id instance phrase grammemes translations word url) translation =
  let
    new_translations =
      (case translations of
        Just trs ->
          Just ((List.map (\tr -> { tr | correct_for_context = False }) trs) ++ [translation])

        Nothing ->
          Nothing)
  in
    TextWord id instance phrase grammemes new_translations word url

removeTranslation : TextWord -> Translation -> TextWord
removeTranslation ((TextWord id instance phrase grammemes translations word url) as text_word) text_word_translation =
  case translations of
    Just trs ->
      let
        new_translations = List.filter (\tr -> tr.id /= text_word_translation.id) trs
      in
        TextWord id instance phrase grammemes (Just new_translations) word url

    -- no translations
    Nothing ->
      text_word

updateTranslation : TextWord -> Translation -> TextWord
updateTranslation ((TextWord id instance phrase grammemes translations word url) as text_word) text_word_translation =
  case translations of
    Just trs ->
      let
        new_translations =
          List.map (\tr -> if tr.id == text_word_translation.id then text_word_translation else tr) trs
      in
        TextWord id instance phrase grammemes (Just new_translations) word url

    -- word has no translations
    Nothing ->
      text_word


setNoTRCorrectForContext : TextWord -> TextWord
setNoTRCorrectForContext ((TextWord id instance phrase grammemes translations word url) as text_word) =
  case translations of
    Just trs ->
      let
        new_translations = List.map (\tr -> { tr | correct_for_context = False }) trs
      in
        TextWord id instance phrase grammemes (Just new_translations) word url

    Nothing ->
      text_word