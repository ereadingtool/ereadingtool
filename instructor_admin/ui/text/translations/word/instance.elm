module Text.Translations.Word.Instance exposing (..)

import Text.Translations exposing (..)

import Text.Model


type WordInstance = WordInstance Id Instance Token (Maybe Text.Model.Translation)


id : WordInstance -> Id
id (WordInstance id instance token translation) =
  id

word : WordInstance -> Word
word (WordInstance _ _ word _) =
  word

normalizeToken : String -> String
normalizeToken = String.toLower

new : Id -> Instance -> Token -> Maybe Text.Model.Translation -> WordInstance
new id instance token translation =
  WordInstance id instance token translation
