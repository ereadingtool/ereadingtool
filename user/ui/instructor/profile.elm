module Instructor.Profile exposing (..)

import Html exposing (Html, div)
import Html.Attributes exposing (classList, attribute)


type alias InstructorProfileParams = { id: Maybe Int, username: String }

type InstructorProfile = InstructorProfile InstructorProfileParams

init_profile : InstructorProfileParams -> InstructorProfile
init_profile params =
  InstructorProfile params

username : InstructorProfile -> String
username (InstructorProfile attrs) = attrs.username

view_instructor_profile_header : InstructorProfile -> List (Html msg)
view_instructor_profile_header (InstructorProfile attrs) = [
    Html.div [] [ Html.a [attribute "href" "/profile/instructor/"] [ Html.text attrs.username ] ]
  ]
