module User.Profile exposing (ProfileID, ProfileType, profileIDtoString)


type ProfileID
    = ProfileID Int


type ProfileType
    = ProfileType String


profileIDtoString : ProfileID -> String
profileIDtoString (ProfileID id) =
    String.fromInt id
