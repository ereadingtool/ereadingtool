module Text.Translations.Word.Instance exposing (..)

import Text.Translations exposing (..)

import Text.Translations.TextWord exposing (TextWord)

type WordInstance = WordInstance Instance Token (Maybe TextWord)


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
