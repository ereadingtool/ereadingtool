module User.Instructor.Profile.Init exposing (init)

import Dict
import Menu.Items
import User.Instructor.Profile as InstructorProfile
import User.Instructor.Profile.Flags as InstructorProfileFlags
import User.Instructor.Profile.Model exposing (Model)
import User.Instructor.Profile.Msg exposing (Msg)
import User.Instructor.Resource as InstructorResource


init : InstructorProfileFlags.Flags -> ( Model, Cmd Msg )
init flags =
    ( { flags = flags
      , instructor_invite_uri = InstructorResource.flagsToInstructorURI flags
      , profile = InstructorProfile.initProfile flags.instructor_profile
      , menu_items = Menu.Items.initMenuItems flags
      , new_invite_email = Nothing
      , errors = Dict.empty
      }
    , Cmd.none
    )
