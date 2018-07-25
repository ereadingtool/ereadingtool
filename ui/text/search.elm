module Text.Search exposing (new, filter_params, tagOptionsToDict, tag_search, set_tag_search, difficulty_search
  , TextSearch)

import Dict exposing (Dict)
import Search exposing (..)

import Text.Search.Option exposing (SearchOption)

import Text.Search.Tag exposing (TagSearch)
import Text.Search.Difficulty exposing (DifficultySearch)

type TextSearch = TextSearch SearchEndpoint TagSearch DifficultySearch


new : SearchEndpoint -> TagSearch -> DifficultySearch -> TextSearch
new endpoint tag_search difficulty_search =
  TextSearch endpoint tag_search difficulty_search

tagOptionsToDict : TextSearch -> Dict String SearchOption
tagOptionsToDict text_search =
  Text.Search.Tag.optionsToDict (tag_search text_search)

difficultyOptionsToDict : TextSearch -> Dict String SearchOption
difficultyOptionsToDict text_search =
  Text.Search.Difficulty.optionsToDict (difficulty_search text_search)

tag_search : TextSearch -> TagSearch
tag_search (TextSearch _ tag_search _) = tag_search

set_tag_search : TextSearch -> TagSearch -> TextSearch
set_tag_search (TextSearch id _ difficulty_search) tag_search =
  TextSearch id tag_search difficulty_search

difficulty_search : TextSearch -> DifficultySearch
difficulty_search (TextSearch _ _ difficulty_search) = difficulty_search

filter_params : TextSearch -> List String
filter_params text_search =
  let
    selected = \opts -> Dict.filter (\k v -> Text.Search.Option.selected v) opts
    selected_tag_options = selected (tagOptionsToDict text_search)
    selected_difficulty_options = selected (difficultyOptionsToDict text_search)
  in
      List.foldr (++) []
   <| List.map (\(k, v) -> [k, "=", Text.Search.Option.label v])
   <| Dict.toList
   <| Dict.union selected_tag_options selected_difficulty_options