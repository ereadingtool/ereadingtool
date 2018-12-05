module Text.Search.Tag exposing (TagSearch, new, optionsToDict, select_tag, input_id, filter_params)

import Search exposing (..)

import Text.Search.Option exposing (SearchOption, SearchOptions)

import Dict exposing (Dict)


type TagSearch = TagSearch ID SearchOptions Error
type alias Tag = String


new : ID -> SearchOptions -> TagSearch
new id options =
  TagSearch id options Search.emptyError

selected_options : TagSearch -> List SearchOption
selected_options (TagSearch _ options _) =
  Text.Search.Option.selectedOptions options

optionsToDict : TagSearch -> Dict String SearchOption
optionsToDict (TagSearch _ options _) =
  Text.Search.Option.optionsToDict options

select_tag : TagSearch -> Tag -> Selected -> TagSearch
select_tag ((TagSearch id options err) as tag_search) tag selected =
  TagSearch id
    (Text.Search.Option.dictToOptions <|
      Dict.update tag
      (\v -> case v of
        Just option ->
          Just <| Text.Search.Option.setSelected option selected
        Nothing -> Nothing) (optionsToDict tag_search)) err

input_id : TagSearch -> String
input_id (TagSearch id _ _) = id

filter_params : TagSearch -> List String
filter_params tag_search =
  List.map (\opt -> String.join "" ["tag", "=", Text.Search.Option.value opt]) (selected_options tag_search)