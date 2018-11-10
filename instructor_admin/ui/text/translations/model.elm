module Text.Translations.Model exposing (..)

import Dict exposing (Dict)

import Text.Model


type alias Model = {
   words: Dict String Text.Model.TextWords
 , current_letter: Maybe String }


init : Model
init = {
   words=Dict.empty
 , current_letter=Nothing }