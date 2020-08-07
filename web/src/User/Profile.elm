module User.Profile exposing (..)

import Html exposing (Html)
import Http exposing (..)
import User.Instructor.Profile
import User.Instructor.View
import Menu.Logout
import Menu.Msg exposing (Msg)
import User.Student.Profile
import User.Student.Profile.Resource
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


logout : Profile -> (Result Http.Error Menu.Logout.LogOutResp -> msg) -> Cmd msg
logout profile logout_msg =
    case profile of
        Student student_profile ->
            User.Student.Profile.Resource.logout student_profile logout_msg

        Instructor instructor_profile ->
            User.Instructor.Profile.logout instructor_profile logout_msg

        EmptyProfile ->
            Cmd.none
