module Flags exposing (CSRFToken, ProfileID, ProfileType, Flags)

type alias CSRFToken = String
type alias ProfileID = Int

type alias ProfileType = String

type alias Flags = { csrftoken : CSRFToken }