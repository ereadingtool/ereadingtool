module Instructor.Profile exposing (..)

type alias InstructorProfileParams = { id: Maybe Int, username: String }

type InstructorProfile = InstructorProfile InstructorProfileParams

init_profile : InstructorProfileParams -> InstructorProfile
init_profile params =
  InstructorProfile params

username : InstructorProfile -> String
username (InstructorProfile attrs) = attrs.username

attrs : InstructorProfile -> InstructorProfileParams
attrs (InstructorProfile attrs) = attrs

logout : InstructorProfile -> Cmd msg
logout instructor_profile =
  Cmd.none