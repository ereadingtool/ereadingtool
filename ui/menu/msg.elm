module Menu.Msg exposing (..)

import Student.Profile.Model exposing (StudentProfile)
import Instructor.Profile exposing (InstructorProfile)

type Msg =
    InstructorLogout InstructorProfile
  | StudentLogout StudentProfile
