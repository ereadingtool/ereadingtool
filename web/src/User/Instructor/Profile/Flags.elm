module User.Instructor.Profile.Flags exposing (Flags)

import Flags
import User.Instructor.Profile as InstructorProfile


type alias Flags =
    Flags.AuthedFlags
        { instructor_invite_uri : String
        , instructor_profile : InstructorProfile.InstructorProfileParams
        }
