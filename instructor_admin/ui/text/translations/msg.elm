module Text.Translations.Msg exposing (Msg, Msg(..))

import Http
import Dict exposing (Dict)

import Text.Model


type Msg =
    ShowLetter String
  | MakeCorrectForContext Text.Model.TextWordTranslation
  | UpdateTextTranslations (Result Http.Error (Dict String Text.Model.TextWords))
