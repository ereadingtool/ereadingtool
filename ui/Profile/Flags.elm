module Profile.Flags exposing (Flags)

import Flags
import Instructor.Profile
import Student.Profile


type alias UnAuthedFlags =
    { csrftoken : Flags.CSRFToken
    }


type alias Flags a =
    Flags.AuthedFlags
        { a
            | profile_id : Int
            , profile_type : String
            , instructor_profile : Maybe Instructor.Profile.InstructorProfileParams
            , student_profile : Maybe Student.Profile.StudentProfileParams
        }
