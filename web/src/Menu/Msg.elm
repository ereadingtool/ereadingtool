module Menu.Msg exposing (Msg(..))

import User.Instructor.Profile exposing (InstructorProfile)
import User.Student.Profile exposing (StudentProfile)


type Msg
    = InstructorLogout InstructorProfile
    | StudentLogout StudentProfile
