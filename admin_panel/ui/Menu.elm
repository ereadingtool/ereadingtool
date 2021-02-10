module Menu exposing (..)

type Select = Select Bool
type URI = URI String
type LinkText = LinkText String


selected : Select -> Bool
selected (Select selected) =
  selected

uriToString : URI -> String
uriToString (URI uri) =
  uri

linkTextToString : LinkText -> String
linkTextToString (LinkText text) =
  text