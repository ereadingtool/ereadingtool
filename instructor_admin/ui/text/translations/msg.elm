module Text.Translations.Msg exposing (Msg, Msg(..))

import Http
import Dict exposing (Dict)
import Array exposing (Array)

import Text.Model
import Text.Translations

import Text.Decode


type Msg =
  -- action msgs
    AddToMergeWords Text.Model.WordInstance
  | RemoveFromMergeWords Text.Model.WordInstance
  | EditWord Text.Model.WordInstance
  | CloseEditWord Text.Model.WordInstance
  | MakeCorrectForContext Text.Model.TextWordTranslation
  | DeleteTextWord Text.Model.TextWord
  | UpdateNewTranslationForTextWord Text.Model.TextWord String
  | AddTextWord Text.Model.WordInstance
  | SubmitNewTranslationForTextWord Text.Model.TextWord
  | DeleteTranslation Text.Model.TextWord Text.Model.TextWordTranslation
  | MatchTranslations Text.Model.WordInstance
  | SelectedText (Maybe String)
  -- result msgs
  | DeletedTextWord (Result Http.Error Text.Model.TextWord)
  | UpdatedTextWords (Result Http.Error (List Text.Model.TextWord))
  | UpdateTextTranslations (Result Http.Error (Dict Text.Translations.Word (Array Text.Model.TextWord)))
  | UpdateTextTranslation (Result Http.Error (Text.Translations.Word, Int, Text.Model.TextWordTranslation))
  | SubmittedTextTranslation (Result Http.Error (Text.Translations.Word, Int, Text.Model.TextWordTranslation))
  | DeletedTranslation (Result Http.Error Text.Decode.TextWordTranslationDeleteResp)
