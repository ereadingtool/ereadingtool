module Text.Translations.Word.Instance exposing (..)

import Text.Translations exposing (..)

import Set exposing (Set)

import Text.Translations.TextWord exposing (TextWord)

type WordInstance = WordInstance Instance Token (Maybe TextWord)


grammemeValue : WordInstance -> String -> Maybe String
grammemeValue word_instance grammeme_name =
  case (textWord word_instance) of
    Just text_word ->
      Text.Translations.TextWord.grammemeValue text_word grammeme_name

    Nothing ->
      Nothing

grammemeKeys : Set String
grammemeKeys =
  Text.Translations.grammemeKeys

grammemes : WordInstance -> Maybe Grammemes
grammemes word_instance =
  case (textWord word_instance) of
    Just text_word ->
      Text.Translations.TextWord.grammemes text_word

    Nothing ->
      Nothing

id : WordInstance -> Id
id (WordInstance instance token _) =
  String.join "_" [toString instance, token]

textWord : WordInstance -> Maybe TextWord
textWord (WordInstance _ _ text_word) =
  text_word

word : WordInstance -> Token
word (WordInstance _ word _) =
  word

normalizeToken : String -> String
normalizeToken = String.toLower

new : Instance -> Token -> Maybe TextWord -> WordInstance
new instance token text_word =
  WordInstance instance token text_word
