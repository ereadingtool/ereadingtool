module TextReader.TextWord exposing (..)

import Dict exposing (Dict)

import Text.Translations exposing (..)

import Text.Translations.Word.Kind
import Text.Translations.TextWord


type alias Translation = {
   correct_for_context: Bool
 , text: String
 }

type alias Translations = List Translation

type alias TextWordParams = {
    id: Int
  , instance: Int
  , phrase: String
  , grammemes: Maybe (List (String, String))
  , translations: Maybe Translations
  , word: (String, Maybe TextGroupDetails)
  }


type TextWord = TextWord Int Instance Phrase (Maybe Grammemes) (Maybe Translations) Text.Translations.Word.Kind.WordKind


instance : TextWord -> Instance
instance (TextWord _ instance _ _ _ _) =
  instance

phrase : TextWord -> Phrase
phrase (TextWord _ _ phrase _ _ _) =
  phrase

word : TextWord -> Text.Translations.Word.Kind.WordKind
word (TextWord _ _ _ _ _ word) =
  word

wordType : TextWord -> String
wordType text_word =
  Text.Translations.TextWord.wordTypeToString (word text_word)

group : TextWord -> Maybe TextGroupDetails
group (TextWord _ _ _ _ _ word) =
  Text.Translations.TextWord.wordKindToGroup word

grammemes : TextWord -> Maybe Grammemes
grammemes (TextWord _ _ _ grammemes _ _) =
  grammemes

grammemesToString : TextWord -> String
grammemesToString text_word =
  case grammemes text_word of
    Just grs ->
         String.join ", "
      <| List.map (\(g, v) -> g ++ ": " ++ v)
      <| Dict.toList grs

    Nothing ->
      ""

hasTranslations : TextWord -> Bool
hasTranslations text_word =
  case translations text_word of
    Just trs ->
      True

    Nothing ->
      False

translations : TextWord -> Maybe Translations
translations (TextWord _ _ _ _ translations _) =
  translations

new : Int -> Instance -> Phrase -> Maybe Grammemes -> Maybe Translations -> Text.Translations.Word.Kind.WordKind -> TextWord
new id instance phrase grammemes translations word =
  TextWord id instance phrase grammemes translations word

newGrammemeFromList : Maybe (List (String, String)) -> Grammemes
newGrammemeFromList grammemes =
  case grammemes of
    Just grs ->
      Dict.fromList grs

    Nothing ->
      Dict.empty

newFromParams : TextWordParams -> TextWord
newFromParams params =
  TextWord
    params.id params.instance params.phrase
    (Just (newGrammemeFromList params.grammemes))
    params.translations
    (Text.Translations.TextWord.strToWordType params.word)