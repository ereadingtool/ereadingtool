module Instructor.Profile.Flags exposing (Flags)

import Flags
import Instructor.Profile


type alias Flags =
  Flags.AuthedFlags {
    instructor_invite_uri: String
  , instructor_profile : Instructor.Profile.InstructorProfileParams }
