module Text.Search.Option exposing (SearchOption, SearchOptions, newOptions, newOption, optionsToDict, dictToOptions
  , selected, setSelected, label, options, value, selectedOptions, listToOptions)

import Dict exposing (Dict)

import Search exposing (..)

type SearchOption = SearchOption Value Label Selected

{-could use an ordered dictionary for options
 (http://package.elm-lang.org/packages/wittjosiah/elm-ordered-dict/latest) -}
type SearchOptions = SearchOptions (List SearchOption)

options : SearchOptions -> List SearchOption
options (SearchOptions options) =
  options

selectedOptions : SearchOptions -> List SearchOption
selectedOptions search_options =
  List.filter selected (options search_options)

newOption : (Value, Label) -> Selected -> SearchOption
newOption (value, label) selected =
  SearchOption value label selected

value : SearchOption -> Value
value (SearchOption value _ _) =
  value

label : SearchOption -> Label
label (SearchOption _ label _) = label

newOptions : List (Value, Label) -> SearchOptions
newOptions options =
  SearchOptions
    (List.map (\(value, label) -> newOption (value, label) False) options)

addOption : SearchOptions -> (Value, Label) -> SearchOptions
addOption (SearchOptions options) (value, label) =
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

setSelected : SearchOption -> Bool -> SearchOption
setSelected (SearchOption value label selected) new_selected =
  SearchOption value label new_selected

selected : SearchOption -> Bool
selected (SearchOption _ _ selected) = selected