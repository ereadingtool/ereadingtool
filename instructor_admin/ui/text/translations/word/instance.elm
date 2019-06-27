module Text.Translations.Word.Instance exposing (..)

import Text.Translations exposing (..)

import Set exposing (Set)

import Text.Translations.TextWord exposing (TextWord)

import Text.Translations.Word.Instance.Editing exposing (Editing)
import Text.Translations.Word.Instance.Input exposing (Input)


type WordInstance = WordInstance Instance Token (Maybe TextWord)

type WordInstanceEdit = WordInstanceEdit Editing Input


wordInstanceEdit : Bool -> Bool -> WordInstanceEdit
wordInstanceEdit editing disabled_input =
  WordInstanceEdit (Editing editing) (Input disabled_input)

enableWordInstanceEditing : WordInstanceEdit -> WordInstanceEdit
enableWordInstanceEditing (WordInstanceEdit editing input) =
  WordInstanceEdit (Text.Translations.Word.Instance.Editing.enableEditing) editing input

disableWordInstanceEditing : WordInstanceEdit -> WordInstanceEdit
disableWordInstanceEditing (WordInstanceEdit editing input) =
  WordInstanceEdit (Text.Translations.Word.Instance.Editing.disableEditing editing) input

enableWordInstanceInput : WordInstanceEdit -> WordInstanceEdit
enableWordInstanceInput (WordInstanceEdit editing input) =
  WordInstanceEdit editing (Text.Translations.Word.Instance.Input.enableInput input)

disableWordInstanceInput : WordInstanceEdit -> WordInstanceEdit
disableWordInstanceInput (WordInstanceEdit editing input) =
  Text.Translations.Word.Instance.Input.disableInput input

verifyCanMergeWords : List WordInstance -> Bool
verifyCanMergeWords word_instances =
  List.all hasTextWord word_instances

hasTextWord : WordInstance -> Bool
hasTextWord (WordInstance instance token text_word) =
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
