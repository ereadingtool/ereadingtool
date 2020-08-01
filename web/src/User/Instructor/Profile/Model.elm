module User.Instructor.Profile.Model exposing (Model)

import Dict exposing (Dict)
import Menu.Items
import User.Instructor.Invite as InstructorInvite
import User.Instructor.Profile exposing (InstructorProfile)
import User.Instructor.Profile.Flags as InstructorProfileFlags
import User.Instructor.Resource as InstructorResource


type alias Model =
    { flags : InstructorProfileFlags.Flags
    , profile : InstructorProfile
    , instructor_invite_uri : InstructorResource.InstructorInviteURI
    , menu_items : Menu.Items.MenuItems
    , new_invite_email : Maybe InstructorInvite.Email
    , errors : Dict String String
    }
