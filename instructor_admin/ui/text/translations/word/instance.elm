module Text.Translations.Word.Instance exposing (..)

import Text.Translations exposing (..)

import Text.Translations.TextWord exposing (TextWord)

type WordInstance = WordInstance Id Instance Token (Maybe TextWord)


id : WordInstance -> Id
id (WordInstance id _ _ _) =
  id

textWord : WordInstance -> Maybe TextWord
textWord (WordInstance _ _ _ text_word) =
  text_word

word : WordInstance -> Token
word (WordInstance _ _ word _) =
  word

normalizeToken : String -> String
normalizeToken = String.toLower

new : Id -> Instance -> Token -> Maybe TextWord -> WordInstance
new id instance token text_word =
  WordInstance id instance token text_word
