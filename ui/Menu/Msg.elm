module Menu.Msg exposing (..)

import Instructor.Profile exposing (InstructorProfile)
import Student.Profile exposing (StudentProfile)


type Msg
    = InstructorLogout InstructorProfile
    | StudentLogout StudentProfile
