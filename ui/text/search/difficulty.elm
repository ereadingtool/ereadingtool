module Text.Search.Difficulty exposing (DifficultySearch, new, options, optionsToDict, select_difficulty, filter_params)

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

selected_options : DifficultySearch -> List SearchOption
selected_options (DifficultySearch _ options _) =
  Text.Search.Option.selected_options options

optionsToDict : DifficultySearch -> Dict String SearchOption
optionsToDict (DifficultySearch _ options _) =
  Text.Search.Option.optionsToDict options

select_difficulty : DifficultySearch -> Difficulty -> Selected -> DifficultySearch
select_difficulty ((DifficultySearch id _ err) as difficulty_search) difficulty selected =
  DifficultySearch id
    (Text.Search.Option.listToOptions
      (List.map (\opt ->
        if (Text.Search.Option.value opt == difficulty)
        then (Text.Search.Option.set_selected opt selected)
        else opt) (options difficulty_search))) err

filter_params : DifficultySearch -> List String
filter_params difficulty_search =
  List.map (\opt ->
    String.join "" ["difficulty", "=", Text.Search.Option.value opt]
  ) (selected_options difficulty_search)