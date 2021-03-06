module Search exposing
    ( Error
    , ID
    , Label
    , Selected
    , Value
    , emptyError
    )


type alias ID =
    String


type alias Value =
    String


type alias Label =
    String


type alias Selected =
    Bool


type Error
    = Error Bool String


emptyError : Error
emptyError =
    Error False ""
