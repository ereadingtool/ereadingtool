module Text.Translations.Word.Instance exposing (..)

import Text.Translations exposing (..)

import Set exposing (Set)

import Text.Translations.TextWord exposing (TextWord)


type WordInstance = WordInstance Int Instance Token (Maybe TextWord)


verifyCanMergeWords : List WordInstance -> Bool
verifyCanMergeWords word_instances =
  List.all hasTextWord word_instances

hasTextWord : WordInstance -> Bool
hasTextWord (WordInstance section_number instance token text_word) =
  case text_word of
    Just tw ->
      True

    Nothing ->
      False

grammemeValue : WordInstance -> String -> Maybe String
grammemeValue word_instance grammeme_name =
  case (textWord word_instance) of
    Just text_word ->
      Text.Translations.TextWord.grammemeValue text_word grammeme_name

    Nothing ->
      Nothing

grammemeKeys : Set String
grammemeKeys =
  Text.Translations.expectedGrammemeKeys

grammemes : WordInstance -> Maybe Grammemes
grammemes word_instance =
  case (textWord word_instance) of
    Just text_word ->
      Text.Translations.TextWord.grammemes text_word

    Nothing ->
      Nothing

sectionNumber : WordInstance -> Int
sectionNumber (WordInstance section_number _ _ _) =
  section_number

id : WordInstance -> Id
id (WordInstance section_number instance token _) =
  String.join "_" [toString section_number, toString instance, token]

textWord : WordInstance -> Maybe TextWord
textWord (WordInstance _ _ _ text_word) =
  text_word

instance : WordInstance -> Instance
instance (WordInstance _ instance _ _) =
  instance

word : WordInstance -> Token
word (WordInstance _ _ word _) =
  word

normalizeToken : String -> String
normalizeToken = String.toLower

new : Int -> Instance -> Token -> Maybe TextWord -> WordInstance
new section_number instance token text_word =
  WordInstance section_number instance token text_word
