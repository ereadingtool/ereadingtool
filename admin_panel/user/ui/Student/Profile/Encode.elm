module Student.Profile.Encode exposing (..)

import Json.Encode

import Student.Profile


profileEncoder : Student.Profile.StudentProfile -> Json.Encode.Value
profileEncoder student_profile =
  let
    encode_pref =
      (case (Student.Profile.studentDifficultyPreference student_profile) of
        Just difficulty ->
          Json.Encode.string (Tuple.first difficulty)

        Nothing ->
          Json.Encode.null)

    username =
      (case Student.Profile.studentUserName student_profile of
         Just username ->
           Json.Encode.string (Student.Profile.studentUserNameToString username)

         Nothing ->
           Json.Encode.null)
  in
    Json.Encode.object [ ("difficulty_preference", encode_pref), ("username", username) ]

username_valid_encode : String -> Json.Encode.Value
username_valid_encode username =
  Json.Encode.object [("username", Json.Encode.string username)]

consentEncoder : Bool -> Json.Encode.Value
consentEncoder consented =
  Json.Encode.object [
    ("consent_to_research", Json.Encode.bool consented)
  ]