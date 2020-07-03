module Menu exposing
    ( LinkText(..)
    , Select(..)
    , URI(..)
    , linkTextToString
    , selected
    , uriToString
    )


type Select
    = Select Bool


type URI
    = URI String


type LinkText
    = LinkText String


selected : Select -> Bool
selected (Select is_selected) =
    is_selected


uriToString : URI -> String
uriToString (URI uri) =
    uri


linkTextToString : LinkText -> String
linkTextToString (LinkText text) =
    text
