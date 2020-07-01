module Field exposing
    ( FieldAttributes
    , ID
    )

import Json.Decode as Decode


type alias ID =
    Int


type alias Editable =
    Bool


type alias Index =
    Int


type alias Error =
    Bool


fieldIDDecoder : Decode.Decoder ID
fieldIDDecoder =
    Decode.int


type alias FieldAttributes a =
    { a | id : String, input_id : String, editable : Bool, error : Bool, index : Int, error_string : String }
