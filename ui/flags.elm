module Flags exposing (..)


type alias CSRFToken = String

type alias UnAuthedFlags = {
    csrftoken : CSRFToken }
