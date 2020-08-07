module Profile exposing (ProfileID, ProfileType, profileID)


type ProfileID = ProfileID Int
type ProfileType = ProfileType String


profileID : ProfileID -> Int
profileID (ProfileID id) =
    id