module Text.Word exposing (..)

import Text.Model


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

removeTranslation : Text.Model.TextWord -> Text.Model.TextWordTranslation -> Text.Model.TextWord
removeTranslation text_word text_word_translation =
  case text_word.translations of
    Just translations ->
      let
        new_translations = List.filter (\tr -> tr.id /= text_word_translation.id) translations
      in
        { text_word | translations = Just new_translations}

    -- no translations
    Nothing ->
      text_word

updateTranslation : Text.Model.TextWord -> Text.Model.TextWordTranslation -> Text.Model.TextWord
updateTranslation text_word text_word_translation =
  case text_word.translations of
    Just translations ->
      let
        new_translations =
          List.map (\tr -> if tr.id == text_word_translation.id then text_word_translation else tr) translations
      in
        { text_word | translations = Just new_translations }

    -- word has no translations
    Nothing ->
      text_word


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