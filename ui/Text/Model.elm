module Text.Model exposing (..)

import Array exposing (Array)
import DateTime exposing (DateTime)
import Dict exposing (Dict)
import Text.Section.Model exposing (emptyTextSection)
import Text.Translations exposing (..)


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
    , created_dt : Maybe DateTime
    , modified_dt : Maybe DateTime
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
    , last_modified_by : Maybe String
    , tags : Maybe (List String)
    , created_dt : DateTime
    , modified_dt : DateTime
    , last_read_dt : Maybe DateTime
    , text_section_count : Int
    , text_sections_complete : Maybe Int
    , questions_correct : Maybe ( Int, Int )
    , uri : String
    , write_locker : Maybe String
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
