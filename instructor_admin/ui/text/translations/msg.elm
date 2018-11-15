module Text.Translations.Msg exposing (Msg, Msg(..))

import Http
import Dict exposing (Dict)

import Text.Model
import Text.Translations

import Text.Decode


type Msg =
    ShowLetter String
  | MakeCorrectForContext Text.Model.TextWordTranslation
  | UpdateTextTranslations (Result Http.Error (Dict String Text.Model.TextWords))
  | UpdateTextTranslation (Result Http.Error (Text.Translations.Word, Text.Model.TextWordTranslation))
  | UpdateNewTranslationForTextWord Text.Model.TextWord String
  | AddNewTranslationForTextWord Text.Model.TextWord
  | AddedTextTranslation (Result Http.Error (Text.Translations.Word, Text.Model.TextWordTranslation))
  | DeleteTranslation Text.Model.TextWord Text.Model.TextWordTranslation
  | DeletedTranslation (Result Http.Error Text.Decode.TextWordTranslationDeleteResp)
