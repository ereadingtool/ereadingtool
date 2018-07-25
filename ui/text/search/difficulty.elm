module Text.Search.Difficulty exposing (DifficultySearch, new, options, optionsToDict)

import Search exposing (..)

import Text.Search.Option exposing (SearchOption, SearchOptions)
import Dict exposing (Dict)


type DifficultySearch = DifficultySearch ID SearchOptions Error


new : ID -> SearchOptions -> DifficultySearch
new id options =
  DifficultySearch id options Search.emptyError

options : DifficultySearch -> List SearchOption
options (DifficultySearch _ options _) =
  Text.Search.Option.options options

optionsToDict : DifficultySearch -> Dict String SearchOption
optionsToDict (DifficultySearch _ options _) =
  Text.Search.Option.optionsToDict options