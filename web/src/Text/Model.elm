module Text.Model exposing
    ( Text
    , TextDifficulty
    , TextListItem
    , new_text
    , set_sections
    , set_tags
    )

import Array exposing (Array)
import Dict
import Text.Section.Model exposing (emptyTextSection)
import Text.Translations exposing (..)
import Time exposing (Posix)


type alias TextDifficulty =
    ( String, String )


type alias Text =
    { id : Maybe Int
    , title : String
    , introduction : String
    , author : String
    , source : String
    , difficulty : String
    , conclusion : Maybe String
    , created_by : Maybe String
    , last_modified_by : Maybe String
    , tags : Maybe (List String)
    , created_dt : Maybe Posix
    , modified_dt : Maybe Posix
    , sections : Array Text.Section.Model.TextSection
    , write_locker : Maybe String
    , words : Words
    }


type alias TextListItem =
    { id : Int
    , title : String
    , author : String
    , difficulty : String
    , created_by : String
    , tags : Maybe (List String)
    , created_dt : Posix
    , modified_dt : Posix
    , last_read_dt : Maybe Posix
    , text_section_count : Int
    , text_sections_complete : Maybe Int
    , questions_correct : Maybe ( Int, Int )
    }


new_text : Text
new_text =
    { id = Nothing
    , title = ""
    , author = ""
    , source = ""
    , difficulty = ""
    , introduction = ""
    , conclusion = Nothing
    , tags = Nothing
    , created_by = Nothing
    , last_modified_by = Nothing
    , created_dt = Nothing
    , modified_dt = Nothing
    , sections = Array.fromList [ Text.Section.Model.emptyTextSection 0 ]
    , write_locker = Nothing
    , words = Dict.empty
    }


set_sections : Text -> Array Text.Section.Model.TextSection -> Text
set_sections text text_sections =
    { text | sections = text_sections }


set_tags : Text -> Maybe (List String) -> Text
set_tags text tags =
    { text | tags = tags }
