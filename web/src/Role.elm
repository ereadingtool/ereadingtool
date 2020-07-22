module Role exposing (Role, decoder, isInstructor, isStudent)

import Json.Decode as Decode exposing (Decoder)


type Role
    = Student
    | Instructor


isStudent : Role -> Bool
isStudent role =
    case role of
        Student ->
            True

        Instructor ->
            False


isInstructor : Role -> Bool
isInstructor role =
    case role of
        Student ->
            False

        Instructor ->
            True


decoder : String -> Decoder Role
decoder roleString =
    case roleString of
        "student" ->
            Decode.succeed Student

        "instructor" ->
            Decode.succeed Instructor

        _ ->
            Decode.fail roleString
