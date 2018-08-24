module Text.Search exposing (new, filter_params, tagOptionsToDict, tag_search, set_tag_search, difficulty_search
  , set_difficulty_search, TextSearch, add_difficulty_to_search)

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

set_difficulty_search : TextSearch -> DifficultySearch -> TextSearch
set_difficulty_search (TextSearch endpoint tag_search _) difficulty_search =
  TextSearch endpoint tag_search difficulty_search

add_difficulty_to_search : TextSearch -> String -> Bool -> TextSearch
add_difficulty_to_search text_search difficulty selected =
  let
    new_difficulty_search = Text.Search.Difficulty.select_difficulty (difficulty_search text_search) difficulty selected
  in
    set_difficulty_search text_search new_difficulty_search

set_tag_search : TextSearch -> TagSearch -> TextSearch
set_tag_search (TextSearch id _ difficulty_search) tag_search =
  TextSearch id tag_search difficulty_search

difficulty_search : TextSearch -> DifficultySearch
difficulty_search (TextSearch _ _ difficulty_search) = difficulty_search

filter_params : TextSearch -> List String
filter_params text_search =
  let
    difficulty_filter_params = Text.Search.Difficulty.filter_params (difficulty_search text_search)
    tag_filter_params = Text.Search.Tag.filter_params (tag_search text_search)
  in
    difficulty_filter_params ++ tag_filter_params