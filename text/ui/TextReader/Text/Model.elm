module TextReader.Text.Model exposing (..)

import Date exposing (Date)


type alias Text =
    { id : Int
    , title : String
    , introduction : String
    , author : String
    , source : String
    , difficulty : String
    , conclusion : Maybe String
    , created_by : Maybe String
    , last_modified_by : Maybe String
    , tags : Maybe (List String)
    , created_dt : Maybe Date
    , modified_dt : Maybe Date
    }


emptyText : Text
emptyText =
    { id = 0
    , title = ""
    , introduction = ""
    , author = ""
    , source = ""
    , difficulty = ""
    , conclusion = Nothing
    , created_by = Nothing
    , last_modified_by = Nothing
    , tags = Nothing
    , created_dt = Nothing
    , modified_dt = Nothing
    }
