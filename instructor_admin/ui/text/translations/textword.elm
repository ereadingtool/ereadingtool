module Text.Translations.TextWord exposing (..)

import Text.Translations exposing (..)


type Word = Word (Maybe TextGroupDetails) | CompoundWord

type TextWord = TextWord Int Instance Phrase Grammemes (Maybe Translations) Word


instance : TextWord -> Int
instance (TextWord _ instance _ _ _ _) =
  instance

group : TextWord -> Maybe TextGroupDetails
group (TextWord _ _ _ _ _ word) =
  case word of
    Word group_details ->
      group_details

    CompoundWord ->
      Nothing

id : TextWord -> Int
id (TextWord id _ _ _ _ _) =
  id

new : Int -> Instance -> Phrase -> Grammemes -> Maybe Translations -> Word -> TextWord
new id instance phrase grammemes translations word =
  TextWord id instance phrase grammemes translations word

phrase : TextWord -> Phrase
phrase (TextWord _ _ phrase _ _ _) =
  phrase

translations : TextWord -> Maybe Translations
translations (TextWord _ _ _ _ translations _) =
  translations

addTranslation : TextWord -> Translation -> TextWord
addTranslation (TextWord id instance phrase grammemes translations word) translation =
  let
    new_translations =
      (case translations of
        Just trs ->
          Just (trs ++ [translation])

        Nothing ->
          Nothing)
  in
    TextWord id instance phrase grammemes new_translations word

removeTranslation : TextWord -> Translation -> TextWord
removeTranslation ((TextWord id instance phrase grammemes translations word) as text_word) text_word_translation =
  case translations of
    Just trs ->
      let
        new_translations = List.filter (\tr -> tr.id /= text_word_translation.id) trs
      in
        TextWord id instance phrase grammemes (Just new_translations) word

    -- no translations
    Nothing ->
      text_word

updateTranslation : TextWord -> Translation -> TextWord
updateTranslation ((TextWord id instance phrase grammemes translations word) as text_word) text_word_translation =
  case translations of
    Just trs ->
      let
        new_translations =
          List.map (\tr -> if tr.id == text_word_translation.id then text_word_translation else tr) trs
      in
        TextWord id instance phrase grammemes (Just new_translations) word

    -- word has no translations
    Nothing ->
      text_word


setNoTRCorrectForContext : TextWord -> TextWord
setNoTRCorrectForContext ((TextWord id instance phrase grammemes translations word) as text_word) =
  case translations of
    Just trs ->
      let
        new_translations = List.map (\tr -> { tr | correct_for_context = False }) trs
      in
        TextWord id instance phrase grammemes (Just new_translations) word

    Nothing ->
      text_word