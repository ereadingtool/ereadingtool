module Text.Search exposing
    ( TextSearch
    , addDifficultyToSearch
    , difficultySearch
    , filterParams
    , new
    , setStatusSearch
    , setTagSearch
    , statusSearch
    , tagSearch
    )

import Dict exposing (Dict)
import Text.Search.Difficulty exposing (DifficultySearch)
import Text.Search.Option exposing (SearchOption)
import Text.Search.ReadingStatus exposing (TextReadStatusSearch)
import Text.Search.Tag exposing (TagSearch)


type TextSearch
    = TextSearch TagSearch DifficultySearch TextReadStatusSearch


new : TagSearch -> DifficultySearch -> TextReadStatusSearch -> TextSearch
new tag_search difficulty_search status_search =
    TextSearch tag_search difficulty_search status_search


tagOptionsToDict : TextSearch -> Dict String SearchOption
tagOptionsToDict text_search =
    Text.Search.Tag.optionsToDict (tagSearch text_search)


difficultyOptionsToDict : TextSearch -> Dict String SearchOption
difficultyOptionsToDict text_search =
    Text.Search.Difficulty.optionsToDict (difficultySearch text_search)


tagSearch : TextSearch -> TagSearch
tagSearch (TextSearch tag_search _ _) =
    tag_search


statusSearch : TextSearch -> TextReadStatusSearch
statusSearch (TextSearch _ _ status_search) =
    status_search


setStatusSearch : TextSearch -> TextReadStatusSearch -> TextSearch
setStatusSearch (TextSearch tag_search difficulty_search _) status_search =
    TextSearch tag_search difficulty_search status_search


setDifficultySearch : TextSearch -> DifficultySearch -> TextSearch
setDifficultySearch (TextSearch tag_search _ status_search) difficulty_search =
    TextSearch tag_search difficulty_search status_search


addDifficultyToSearch : TextSearch -> String -> Bool -> TextSearch
addDifficultyToSearch text_search difficulty selected =
    let
        new_difficulty_search =
            Text.Search.Difficulty.selectDifficulty (difficultySearch text_search) difficulty selected
    in
    setDifficultySearch text_search new_difficulty_search


setTagSearch : TextSearch -> TagSearch -> TextSearch
setTagSearch (TextSearch _ difficulty_search status_search) tag_search =
    TextSearch tag_search difficulty_search status_search


difficultySearch : TextSearch -> DifficultySearch
difficultySearch (TextSearch _ difficulty_search _) =
    difficulty_search


filterParams : TextSearch -> List String
filterParams text_search =
    let
        difficulty_filter_params =
            Text.Search.Difficulty.filterParams (difficultySearch text_search)

        tag_filter_params =
            Text.Search.Tag.filterParams (tagSearch text_search)

        status_filter_params =
            Text.Search.ReadingStatus.filterParams (statusSearch text_search)
    in
    difficulty_filter_params ++ tag_filter_params ++ status_filter_params
