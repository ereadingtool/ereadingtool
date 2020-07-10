module Text.Search.Option exposing
    ( SearchOption
    , SearchOptions
    , dictToOptions
    , label
    , listToOptions
    , newOption
    , newOptions
    , options
    , optionsToDict
    , selected
    , selectedOptions
    , setSelected
    , value
    )

import Dict exposing (Dict)
import Search exposing (..)


type SearchOption
    = SearchOption Value Label Selected



{- could use an ordered dictionary for options
   (http://package.elm-lang.org/packages/wittjosiah/elm-ordered-dict/latest)
-}


type SearchOptions
    = SearchOptions (List SearchOption)


options : SearchOptions -> List SearchOption
options (SearchOptions opts) =
    opts


selectedOptions : SearchOptions -> List SearchOption
selectedOptions search_options =
    List.filter selected (options search_options)


newOption : ( Value, Label ) -> Selected -> SearchOption
newOption ( v, l ) is_selected =
    SearchOption v l is_selected


value : SearchOption -> Value
value (SearchOption v _ _) =
    v


label : SearchOption -> Label
label (SearchOption _ l _) =
    l


newOptions : List ( Value, Label ) -> SearchOptions
newOptions opts =
    SearchOptions
        (List.map (\( v, l ) -> newOption ( v, l ) False) opts)


addOption : SearchOptions -> ( Value, Label ) -> SearchOptions
addOption (SearchOptions opts) ( v, l ) =
    SearchOptions (SearchOption v l False :: opts)


optionsToDict : SearchOptions -> Dict String SearchOption
optionsToDict (SearchOptions opts) =
    Dict.fromList (List.map (\option -> ( value option, option )) opts)


listToOptions : List SearchOption -> SearchOptions
listToOptions opts =
    SearchOptions opts


dictToOptions : Dict String SearchOption -> SearchOptions
dictToOptions opts =
    SearchOptions (Dict.values opts)


setSelected : SearchOption -> Bool -> SearchOption
setSelected (SearchOption v l _) new_selected =
    SearchOption v l new_selected


selected : SearchOption -> Bool
selected (SearchOption _ _ is_selected) =
    is_selected
