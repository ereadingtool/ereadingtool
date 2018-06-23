module Flags exposing (CSRFToken, Flags, UnAuthedFlags)

import Profile
import Instructor.Profile

type alias CSRFToken = String

type alias UnAuthedFlags = {
    csrftoken : CSRFToken }

type alias Flags a = { a |
   csrftoken : CSRFToken
 , profile_id : Profile.ProfileID
 , profile_type : Profile.ProfileType
 , instructor_profile : Instructor.Profile.InstructorProfileParams
 , student_profile : Profile.StudentProfileParams }