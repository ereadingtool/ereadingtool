module Profile.Flags exposing (Flags)

import Flags
import User.Instructor.Profile as InstructorProfile
import User.Student.Profile as StudentProfile


type alias UnAuthedFlags =
    { csrftoken : Flags.CSRFToken
    }


type alias Flags a =
    Flags.AuthedFlags
        { a
            | profile_id : Int
            , profile_type : String
            , instructor_profile : Maybe InstructorProfile.InstructorProfileParams
            , student_profile : Maybe StudentProfile.StudentProfileParams
        }
