module Text.Search.Option exposing (SearchOption, SearchOptions, new_options, new_option, optionsToDict, dictToOptions
  , selected, set_selected, label)

import Dict exposing (Dict)

import Search exposing (..)

type SearchOption = SearchOption Value Label Selected

type SearchOptions = SearchOptions (Dict Value SearchOption)

new_option : (Value, Label) -> Selected -> SearchOption
new_option (value, label) selected =
  SearchOption value label selected

new_options : List (Value, Label) -> SearchOptions
new_options options =
  SearchOptions
    <| Dict.fromList
    <| List.map (\(value, label) -> (value, new_option (value, label) False))
       options

add_option : SearchOptions -> (Value, Label) -> SearchOptions
add_option (SearchOptions options) (value, label) =
  SearchOptions (Dict.insert value (SearchOption value label False) options)

optionsToDict : SearchOptions -> Dict String SearchOption
optionsToDict (SearchOptions options) =
  options

dictToOptions : Dict String SearchOption -> SearchOptions
dictToOptions options =
  SearchOptions options

set_selected : SearchOption -> Bool -> SearchOption
set_selected (SearchOption value label selected) new_selected =
  SearchOption value label new_selected

selected : SearchOption -> Bool
selected (SearchOption _ _ selected) = selected

label : SearchOption -> String
label (SearchOption _ label _) = label