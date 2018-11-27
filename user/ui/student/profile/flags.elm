module Student.Profile.Flags exposing (..)

import Flags
import Profile


type alias Flags = {
    csrftoken : Flags.CSRFToken
  , profile_id : Profile.ProfileID
  , welcome: Bool }