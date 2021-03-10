module Text.Search.ReadingStatus exposing
    ( TextReadStatus
    , TextReadStatusSearch
    , filterParams
    , new
    , options
    , selectStatus
    , valueToStatus
    )

import Dict exposing (Dict)
import Search exposing (..)
import Text.Search.Option exposing (SearchOption, SearchOptions)


type TextReadStatus
    = InProgress
    | Read
    | Unread


type TextReadStatusSearch
    = TextReadStatusSearch ID SearchOptions Error


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
new id opts =
    TextReadStatusSearch id opts Search.emptyError


options : TextReadStatusSearch -> List SearchOption
options (TextReadStatusSearch _ opts _) =
    Text.Search.Option.options opts


selectedOptions : TextReadStatusSearch -> List SearchOption
selectedOptions (TextReadStatusSearch _ opts _) =
    Text.Search.Option.selectedOptions opts


optionsToDict : TextReadStatusSearch -> Dict String SearchOption
optionsToDict (TextReadStatusSearch _ opts _) =
    Text.Search.Option.optionsToDict opts


selectStatus : TextReadStatusSearch -> TextReadStatus -> Selected -> TextReadStatusSearch
selectStatus ((TextReadStatusSearch id _ err) as status_search) status selected =
    TextReadStatusSearch id
        (Text.Search.Option.listToOptions
            (List.map
                (\opt ->
                    if Text.Search.Option.value opt == statusToValue status then
                        Text.Search.Option.setSelected opt selected

                    else
                        Text.Search.Option.setSelected opt False
                )
                (options status_search)
            )
        )
        err


filterParams : TextReadStatusSearch -> List String
filterParams status_search =
    List.map
        (\opt ->
            String.join "" [ "status", "=", Text.Search.Option.value opt ]
        )
        (selectedOptions status_search)
