module Text.Translations.Model exposing (..)

import Dict exposing (Dict)

import Text.Model

import Flags


type alias Flags = { csrftoken : Flags.CSRFToken }


type alias Model = {
   words: Dict String Text.Model.TextWords
 , text: Text.Model.Text
 , new_translations: Dict String String
 , flags: Flags
 , current_letter: Maybe String }


init : Flags -> Text.Model.Text -> Model
init flags text = {
   words=Dict.empty
 , text=text
 , new_translations=Dict.empty
 , flags=flags
 , current_letter=Nothing }