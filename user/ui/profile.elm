module Profile exposing (..)

type ProfileID = ProfileID Int
type ProfileType = ProfileType String


profileIDtoString : ProfileID -> String
profileIDtoString (ProfileID id) =
  toString id