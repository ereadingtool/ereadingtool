module Text.Search.Difficulty exposing
    ( DifficultySearch
    , filterParams
    , new
    , options
    , optionsToDict
    , selectDifficulty
    )

import Dict exposing (Dict)
import Search exposing (..)
import Text.Search.Option exposing (SearchOption, SearchOptions)


type alias Difficulty =
    String


type DifficultySearch
    = DifficultySearch ID SearchOptions Error


new : ID -> SearchOptions -> DifficultySearch
new id opts =
    DifficultySearch id opts Search.emptyError


options : DifficultySearch -> List SearchOption
options (DifficultySearch _ opts _) =
    Text.Search.Option.options opts


selectedOptions : DifficultySearch -> List SearchOption
selectedOptions (DifficultySearch _ opts _) =
    Text.Search.Option.selectedOptions opts


optionsToDict : DifficultySearch -> Dict String SearchOption
optionsToDict (DifficultySearch _ opts _) =
    Text.Search.Option.optionsToDict opts


selectDifficulty : DifficultySearch -> Difficulty -> Selected -> DifficultySearch
selectDifficulty ((DifficultySearch id _ err) as difficulty_search) difficulty selected =
    DifficultySearch id
        (Text.Search.Option.listToOptions
            (List.map
                (\opt ->
                    if Text.Search.Option.value opt == difficulty then
                        Text.Search.Option.setSelected opt selected

                    else
                        Text.Search.Option.setSelected opt False
                )
                (options difficulty_search)
            )
        )
        err


filterParams : DifficultySearch -> List String
filterParams difficulty_search =
    List.map
        (\opt ->
            String.join "" [ "difficulty", "=", Text.Search.Option.value opt ]
        )
        (selectedOptions difficulty_search)
