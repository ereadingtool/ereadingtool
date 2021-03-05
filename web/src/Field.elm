module Field exposing
    ( FieldAttributes
    , ID
    )


type alias ID =
    Int


type alias FieldAttributes a =
    { a
        | id : String
        , input_id : String
        , editable : Bool
        , error : Bool
        , index : Int
        , error_string : String
    }
