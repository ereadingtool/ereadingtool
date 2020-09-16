module User.Profile exposing (..)

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
import User.Student.Profile
    exposing
        ( StudentProfile(..)
        , StudentURIs(..)
        )
import User.Student.Profile.Decode
import User.Student.Profile.Resource
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


initProfile :
    { a
        | instructor_profile : Maybe User.Instructor.Profile.InstructorProfileParams
        , student_profile : Maybe User.Student.Profile.StudentProfileParams
    }
    -> Profile
initProfile flags =
    case flags.instructor_profile of
        Just instructor_profile_params ->
            Instructor (User.Instructor.Profile.initProfile instructor_profile_params)

        Nothing ->
            case flags.student_profile of
                Just student_profile_params ->
                    Student (User.Student.Profile.initProfile student_profile_params)

                Nothing ->
                    EmptyProfile


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


retrieveStudentProfile :
    (Result Error User.Student.Profile.StudentProfile -> msg)
    -> ProfileID
    -> User.Student.Resource.StudentEndpointURI
    -> Cmd msg
retrieveStudentProfile msg profile_id student_endpoint_uri =
    let
        request =
            Debug.todo

        -- Http.get
        --     (User.Student.Resource.uriToString (User.Student.Resource.studentEndpointURI student_endpoint_uri))
        --     User.Student.Profile.Decode.studentProfileDecoder
    in
    -- Http.send msg request
    Debug.todo "retrieve student profile"


logout : Profile -> Flags.CSRFToken -> (Result Http.Error Menu.Logout.LogOutResp -> msg) -> Cmd msg
logout profile csrftoken logout_msg =
    case profile of
        Student student_profile ->
            User.Student.Profile.Resource.logout student_profile csrftoken logout_msg

        Instructor instructor_profile ->
            User.Instructor.Profile.logout instructor_profile csrftoken logout_msg

        EmptyProfile ->
            Cmd.none
