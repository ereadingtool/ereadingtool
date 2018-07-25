module Text.Search.Option exposing (SearchOption, SearchOptions, new_options, new_option, optionsToDict, dictToOptions
  , selected, set_selected, label, options, value)

import Dict exposing (Dict)

import Search exposing (..)

type SearchOption = SearchOption Value Label Selected

type SearchOptions = SearchOptions (List SearchOption)

options : SearchOptions -> List SearchOption
options (SearchOptions options) =
  options

new_option : (Value, Label) -> Selected -> SearchOption
new_option (value, label) selected =
  SearchOption value label selected

value : SearchOption -> Value
value (SearchOption value _ _) =
  value

new_options : List (Value, Label) -> SearchOptions
new_options options =
  SearchOptions
    (List.map (\(value, label) -> new_option (value, label) False) options)

add_option : SearchOptions -> (Value, Label) -> SearchOptions
add_option (SearchOptions options) (value, label) =
  SearchOptions ((SearchOption value label False) :: options)

optionsToDict : SearchOptions -> Dict String SearchOption
optionsToDict (SearchOptions options) =
  Dict.fromList (List.map (\option -> (value option, option)) options)

dictToOptions : Dict String SearchOption -> SearchOptions
dictToOptions options =
  SearchOptions (Dict.values options)

set_selected : SearchOption -> Bool -> SearchOption
set_selected (SearchOption value label selected) new_selected =
  SearchOption value label new_selected

selected : SearchOption -> Bool
selected (SearchOption _ _ selected) = selected

label : SearchOption -> String
label (SearchOption _ label _) = label