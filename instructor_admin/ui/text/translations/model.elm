module Text.Translations.Model exposing (..)

import Dict exposing (Dict)

import Text.Model
import Text.Translations

import Flags


type alias Flags = { csrftoken : Flags.CSRFToken }

type alias Model = {
   words: Dict Text.Translations.Word Text.Model.TextWord
 , editing_words: Dict Text.Translations.Word Bool
 , text: Text.Model.Text
 , new_translations: Dict String String
 , flags: Flags }


init : Flags -> Text.Model.Text -> Model
init flags text = {
   words=Dict.empty
 , editing_words=Dict.empty
 , text=text
 , new_translations=Dict.empty
 , flags=flags }


editingWord : Model -> String -> Bool
editingWord model word =
  Maybe.withDefault False (Dict.get word model.editing_words)
