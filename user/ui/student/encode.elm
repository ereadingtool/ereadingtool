module Student.Encode exposing (..)

import Json.Encode as Encode

import Profile

profileEncoder : Profile.StudentProfile -> Encode.Value
profileEncoder student =
  let
    encode_pref =
      (case (Profile.studentDifficultyPreference student) of
        Just difficulty ->
          Encode.string (Tuple.first difficulty)
        _ ->
          Encode.null)
  in
    Encode.object [ ("difficulty_preference", encode_pref) ]
