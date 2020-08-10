module Role exposing (Role(..), decoder)

import Json.Decode as Decode exposing (Decoder)


type Role
    = Student
    | Instructor


decoder : String -> Decoder Role
decoder roleString =
    case roleString of
        "student" ->
            Decode.succeed Student

        "instructor" ->
            Decode.succeed Instructor

        _ ->
            Decode.fail roleString
