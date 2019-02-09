module Text.Translations.Msg exposing (Msg, Msg(..))

import Http
import Dict exposing (Dict)
import Array exposing (Array)

import Text.Model
import Text.Translations

import Text.Translations.Word.Instance exposing (WordInstance)

import Text.Decode


type Msg =
  -- action msgs
  -- merges
    AddToMergeWords WordInstance
  | RemoveFromMergeWords WordInstance
  | MergeWords (List WordInstance)

  -- words
  | AddTextWord WordInstance
  | EditWord WordInstance
  | CloseEditWord WordInstance
  | DeleteTextWord Text.Model.TextWord

  -- translations
  | MakeCorrectForContext Text.Model.Translation
  | UpdateNewTranslationForTextWord Text.Model.TextWord String
  | SubmitNewTranslationForTextWord Text.Model.TextWord
  | DeleteTranslation Text.Model.TextWord Text.Model.Translation
  | MatchTranslations WordInstance

  -- result msgs
  -- words
  | MergedWords (Result Http.Error Text.Decode.TextWordMergeResp)
  | DeletedTextWord (Result Http.Error Text.Model.TextWord)
  | UpdatedTextWords (Result Http.Error (List Text.Model.TextWord))

  -- translations
  | UpdateTextTranslations (Result Http.Error (Dict Text.Translations.Word (Array Text.Model.TextWord)))
  | UpdateTextTranslation (Result Http.Error (Text.Translations.Word, Int, Text.Model.Translation))
  | SubmittedTextTranslation (Result Http.Error (Text.Translations.Word, Int, Text.Model.Translation))
  | DeletedTranslation (Result Http.Error Text.Decode.TextWordTranslationDeleteResp)
