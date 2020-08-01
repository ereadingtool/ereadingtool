module User.Student.Profile.Encode exposing
    ( consentEncoder
    , profileEncoder
    , username_valid_encode
    )

import Json.Encode
import User.Student.Profile as StudentProfile exposing (StudentProfile)


profileEncoder : StudentProfile -> Json.Encode.Value
profileEncoder student_profile =
    let
        encode_pref =
            case StudentProfile.studentDifficultyPreference student_profile of
                Just difficulty ->
                    Json.Encode.string (Tuple.first difficulty)

                Nothing ->
                    Json.Encode.null

        username =
            case StudentProfile.studentUserName student_profile of
                Just uname ->
                    Json.Encode.string (StudentProfile.studentUserNameToString uname)

                Nothing ->
                    Json.Encode.null
    in
    Json.Encode.object [ ( "difficulty_preference", encode_pref ), ( "username", username ) ]


username_valid_encode : String -> Json.Encode.Value
username_valid_encode username =
    Json.Encode.object [ ( "username", Json.Encode.string username ) ]


consentEncoder : Bool -> Json.Encode.Value
consentEncoder consented =
    Json.Encode.object
        [ ( "consent_to_research", Json.Encode.bool consented )
        ]
