module Text.Search.Difficulty exposing (DifficultySearch, new, options, optionsToDict, selectDifficulty, filterParams)

import Search exposing (..)

import Text.Search.Option exposing (SearchOption, SearchOptions)
import Dict exposing (Dict)

type alias Difficulty = String

type DifficultySearch = DifficultySearch ID SearchOptions Error


new : ID -> SearchOptions -> DifficultySearch
new id options =
  DifficultySearch id options Search.emptyError

options : DifficultySearch -> List SearchOption
options (DifficultySearch _ options _) =
  Text.Search.Option.options options

selectedOptions : DifficultySearch -> List SearchOption
selectedOptions (DifficultySearch _ options _) =
  Text.Search.Option.selectedOptions options

optionsToDict : DifficultySearch -> Dict String SearchOption
optionsToDict (DifficultySearch _ options _) =
  Text.Search.Option.optionsToDict options

selectDifficulty : DifficultySearch -> Difficulty -> Selected -> DifficultySearch
selectDifficulty ((DifficultySearch id _ err) as difficulty_search) difficulty selected =
  DifficultySearch id
    (Text.Search.Option.listToOptions
      (List.map (\opt ->
        if (Text.Search.Option.value opt == difficulty)
        then (Text.Search.Option.setSelected opt selected)
        else opt) (options difficulty_search))) err

filterParams : DifficultySearch -> List String
filterParams difficulty_search =
  List.map (\opt ->
    String.join "" ["difficulty", "=", Text.Search.Option.value opt]
  ) (selectedOptions difficulty_search)