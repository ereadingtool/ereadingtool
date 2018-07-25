module Text.Search.Option exposing (SearchOption, SearchOptions, new_options, new_option, optionsToDict, dictToOptions
  , selected, set_selected, label, options, value, selected_options, listToOptions)

import Dict exposing (Dict)

import Search exposing (..)

type SearchOption = SearchOption Value Label Selected

{-could use an ordered dictionary for options
 (http://package.elm-lang.org/packages/wittjosiah/elm-ordered-dict/latest) -}
type SearchOptions = SearchOptions (List SearchOption)

options : SearchOptions -> List SearchOption
options (SearchOptions options) =
  options

selected_options : SearchOptions -> List SearchOption
selected_options search_options =
  List.filter selected (options search_options)

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

listToOptions : List SearchOption -> SearchOptions
listToOptions options =
  SearchOptions options

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