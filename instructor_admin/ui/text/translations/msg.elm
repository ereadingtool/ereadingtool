module Text.Translations.Msg exposing (Msg, Msg(..))

import Http
import Dict exposing (Dict)
import Array exposing (Array)

import Text.Model
import Text.Translations

import Text.Decode


type Msg =
  -- action msgs
    EditWord Text.Model.WordInstance
  | CloseEditWord Text.Model.WordInstance
  | MakeCorrectForContext Text.Model.TextWordTranslation
  | UpdateNewTranslationForTextWord Text.Model.TextWord String
  | SubmitNewTranslationForTextWord Text.Model.TextWord
  | DeleteTranslation Text.Model.TextWord Text.Model.TextWordTranslation
  -- result msgs
  | UpdateTextTranslations (Result Http.Error (Dict Text.Translations.Word Text.Model.TextWord))
  | UpdateTextTranslation (Result Http.Error (Text.Translations.Word, Text.Model.TextWordTranslation))
  | SubmittedTextTranslation (Result Http.Error (Text.Translations.Word, Text.Model.TextWordTranslation))
  | DeletedTranslation (Result Http.Error Text.Decode.TextWordTranslationDeleteResp)
