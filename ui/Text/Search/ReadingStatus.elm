module Text.Search.ReadingStatus exposing (..)

import Search exposing (..)

import Text.Search.Option exposing (SearchOption, SearchOptions)
import Dict exposing (Dict)

type TextReadStatus =
    InProgress
  | Read
  | Unread

type TextReadStatusSearch = TextReadStatusSearch ID SearchOptions Error


statusToValue : TextReadStatus -> Value
statusToValue text_read_status =
  case text_read_status of
    InProgress ->
      "in_progress"

    Read ->
      "read"

    Unread ->
      "unread"

valueToStatus : Value -> TextReadStatus
valueToStatus value =
  case value of
    "in_progress" ->
      InProgress

    "read" ->
      Read

    "unread" ->
      Unread

    _ ->
      Unread

new : ID -> SearchOptions -> TextReadStatusSearch
new id options =
  TextReadStatusSearch id options Search.emptyError

options : TextReadStatusSearch -> List SearchOption
options (TextReadStatusSearch _ options _) =
  Text.Search.Option.options options

selectedOptions : TextReadStatusSearch -> List SearchOption
selectedOptions (TextReadStatusSearch _ options _) =
  Text.Search.Option.selectedOptions options

optionsToDict : TextReadStatusSearch -> Dict String SearchOption
optionsToDict (TextReadStatusSearch _ options _) =
  Text.Search.Option.optionsToDict options

selectStatus : TextReadStatusSearch -> TextReadStatus -> Selected -> TextReadStatusSearch
selectStatus ((TextReadStatusSearch id _ err) as status_search) status selected =
  TextReadStatusSearch id
    (Text.Search.Option.listToOptions
      (List.map (\opt ->
        if (Text.Search.Option.value opt == (statusToValue status))
        then (Text.Search.Option.setSelected opt selected)
        else opt) (options status_search))) err

filterParams : TextReadStatusSearch -> List String
filterParams status_search =
  List.map (\opt ->
    String.join "" ["status", "=", Text.Search.Option.value opt]
  ) (selectedOptions status_search)