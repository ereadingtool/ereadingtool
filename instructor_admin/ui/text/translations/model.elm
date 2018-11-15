module Text.Translations.Model exposing (..)

import Dict exposing (Dict)

import Text.Model

import Flags


type alias Flags = { csrftoken : Flags.CSRFToken }


type alias Model = {
   words: Dict String Text.Model.TextWords
 , new_translations: Dict String String
 , flags: Flags
 , current_letter: Maybe String }


init : Flags -> Model
init flags = {
   words=Dict.empty
 , new_translations=Dict.empty
 , flags=flags
 , current_letter=Nothing }