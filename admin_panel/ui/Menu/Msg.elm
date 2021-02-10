module Menu.Msg exposing (..)

import Student.Profile exposing (StudentProfile)
import Instructor.Profile exposing (InstructorProfile)

type Msg =
    InstructorLogout InstructorProfile
  | StudentLogout StudentProfile
