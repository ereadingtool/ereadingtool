module Instructor.Profile.Init exposing (init)

import Dict exposing (Dict)
import Instructor.Profile
import Instructor.Profile.Flags
import Instructor.Profile.Model exposing (Model)
import Instructor.Profile.Msg exposing (Msg)
import Instructor.Resource
import Menu.Items


init : Instructor.Profile.Flags.Flags -> ( Model, Cmd Msg )
init flags =
    ( { flags = flags
      , instructor_invite_uri = Instructor.Resource.flagsToInstructorURI flags
      , profile = Instructor.Profile.initProfile flags.instructor_profile
      , menu_items = Menu.Items.initMenuItems flags
      , new_invite_email = Nothing
      , errors = Dict.empty
      }
    , Cmd.none
    )
