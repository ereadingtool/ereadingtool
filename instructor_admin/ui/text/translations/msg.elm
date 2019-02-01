module Text.Translations.Msg exposing (Msg, Msg(..))

import Http
import Dict exposing (Dict)
import Array exposing (Array)

import Text.Model
import Text.Translations

import Text.Decode


type Msg =
  -- action msgs
  -- merges
    AddToMergeWords Text.Model.WordInstance
  | RemoveFromMergeWords Text.Model.WordInstance
  | MergeWords (List Text.Model.WordInstance)

  -- words
  | AddTextWord Text.Model.WordInstance
  | EditWord Text.Model.WordInstance
  | CloseEditWord Text.Model.WordInstance
  | DeleteTextWord Text.Model.TextWord

  -- translations
  | MakeCorrectForContext Text.Model.TextWordTranslation
  | UpdateNewTranslationForTextWord Text.Model.TextWord String
  | SubmitNewTranslationForTextWord Text.Model.TextWord
  | DeleteTranslation Text.Model.TextWord Text.Model.TextWordTranslation
  | MatchTranslations Text.Model.WordInstance

  -- result msgs
  -- words
  | MergedWords (Result Http.Error Text.Decode.TextWordMergeResp)
  | DeletedTextWord (Result Http.Error Text.Model.TextWord)
  | UpdatedTextWords (Result Http.Error (List Text.Model.TextWord))

  -- translations
  | UpdateTextTranslations (Result Http.Error (Dict Text.Translations.Word (Array Text.Model.TextWord)))
  | UpdateTextTranslation (Result Http.Error (Text.Translations.Word, Int, Text.Model.TextWordTranslation))
  | SubmittedTextTranslation (Result Http.Error (Text.Translations.Word, Int, Text.Model.TextWordTranslation))
  | DeletedTranslation (Result Http.Error Text.Decode.TextWordTranslationDeleteResp)
