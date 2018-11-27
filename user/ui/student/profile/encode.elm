module Student.Profile.Encode exposing (..)

import Json.Encode

import Student.Profile


profileEncoder : Student.Profile.StudentProfile -> Json.Encode.Value
profileEncoder student =
  let
    encode_pref =
      (case (Student.Profile.studentDifficultyPreference student) of
        Just difficulty ->
          Json.Encode.string (Tuple.first difficulty)

        _ ->
          Json.Encode.null)
    username = Json.Encode.string (Student.Profile.studentUserName student)
  in
    Json.Encode.object [ ("difficulty_preference", encode_pref), ("username", username) ]

username_valid_encode : String -> Json.Encode.Value
username_valid_encode username =
  Json.Encode.object [("username", Json.Encode.string username)]
