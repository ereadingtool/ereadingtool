module Student.Profile.Encode exposing (..)

import Json.Encode as Encode

import Student.Profile.Model exposing (StudentProfile)


profileEncoder : StudentProfile -> Encode.Value
profileEncoder student =
  let
    encode_pref =
      (case (Student.Profile.Model.studentDifficultyPreference student) of
        Just difficulty ->
          Encode.string (Tuple.first difficulty)
        _ ->
          Encode.null)
  in
    Encode.object [ ("difficulty_preference", encode_pref) ]
