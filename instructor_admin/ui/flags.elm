module Flags exposing (CSRFToken, Flags)

type alias CSRFToken = String
type alias Flags = { csrftoken : CSRFToken }