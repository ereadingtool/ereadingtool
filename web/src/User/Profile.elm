module User.Profile exposing
    ( Profile(..)
    , emptyProfile
    , fromInstructorProfile
    , fromStudentProfile
    , toInstructorProfile
    , toStudentProfile
    , view_profile_header
    )

import Flags
import Html exposing (Html, div)
import Http exposing (..)
import Menu.Logout
import Menu.Msg exposing (Msg)
import Profile exposing (..)
import User.Instructor.Profile
    exposing
        ( InstructorProfile(..)
        , InstructorUsername(..)
        )
import User.Instructor.View
import User.Student.Performance.Report as PerformanceReport exposing (PerformanceReport)
import User.Student.Profile
    exposing
        ( StudentProfile(..)
        , StudentURIs(..)
        )
import User.Student.Resource
import User.Student.View


type Profile
    = Student User.Student.Profile.StudentProfile
    | Instructor User.Instructor.Profile.InstructorProfile
    | EmptyProfile


fromStudentProfile : User.Student.Profile.StudentProfile -> Profile
fromStudentProfile student_profile =
    Student student_profile


fromInstructorProfile : User.Instructor.Profile.InstructorProfile -> Profile
fromInstructorProfile instructor_profile =
    Instructor instructor_profile


{-| TODO: probably best to get rid of these empty default profiles
somehow. This may take a fundamental restructuring of the way that
the Profile type works. Some pages require a StudentProfile or
InstructorProfile and it may be better to have them take a Profile and
act accordingly.
-}
toStudentProfile : Profile -> User.Student.Profile.StudentProfile
toStudentProfile profile =
    case profile of
        Student studentProfile ->
            studentProfile

        _ ->
            StudentProfile
                (Just 0)
                (Just (User.Student.Resource.toStudentUsername ""))
                (User.Student.Resource.toStudentEmail "")
                Nothing
                difficulties
                (StudentURIs
                    (User.Student.Resource.toStudentLogoutURI "")
                    (User.Student.Resource.toStudentProfileURI "")
                )
                PerformanceReport.emptyPerformanceReport


toInstructorProfile : Profile -> User.Instructor.Profile.InstructorProfile
toInstructorProfile profile =
    case profile of
        Instructor instructorProfile ->
            instructorProfile

        _ ->
            InstructorProfile
                (Just 0)
                []
                True
                (Just [])
                (User.Instructor.Profile.InstructorUsername "")
                (User.Instructor.Profile.initProfileURIs
                    { logout_uri = ""
                    , profile_uri = ""
                    }
                )


difficulties : List ( String, String )
difficulties =
    [ ( "intermediate_mid", "Intermediate-Mid" )
    , ( "intermediate_high", "Intermediate-High" )
    , ( "advanced_low", "Advanced-Low" )
    , ( "advanced_mid", "Advanced-Mid" )
    ]


emptyProfile : Profile
emptyProfile =
    EmptyProfile


view_profile_header : Profile -> (Msg -> msg) -> Maybe (List (Html msg))
view_profile_header profile top_level_msg =
    case profile of
        Instructor instructor_profile ->
            Just (User.Instructor.View.view_instructor_profile_header instructor_profile top_level_msg)

        Student student_profile ->
            Just (User.Student.View.view_student_profile_header student_profile top_level_msg)

        EmptyProfile ->
            Nothing
