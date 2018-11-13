module Text.Translations.Msg exposing (Msg, Msg(..))

import Http
import Dict exposing (Dict)

import Text.Model
import Text.Translations

type Msg =
    ShowLetter String
  | MakeCorrectForContext Text.Model.TextWordTranslation
  | UpdateTextTranslations (Result Http.Error (Dict String Text.Model.TextWords))
  | UpdateTextTranslation (Result Http.Error (Text.Translations.Word, Text.Model.TextWordTranslation))
