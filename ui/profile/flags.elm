module Profile.Flags exposing (..)

import Profile

import Instructor.Profile
import Student.Profile

import Flags

type alias UnAuthedFlags = {
    csrftoken : Flags.CSRFToken }

type alias Flags a = Flags.AuthedFlags { a |
   profile_id : Profile.ProfileID
 , profile_type : Profile.ProfileType
 , instructor_profile : Maybe Instructor.Profile.InstructorProfileParams
 , student_profile : Maybe Student.Profile.StudentProfileParams }