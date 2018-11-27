module Student.Profile.Model exposing (..)

import Dict exposing (Dict)

import Student.Profile
import Student.Profile.Flags exposing (Flags)
import Student.Profile.Help


type alias UsernameUpdate = { username: String, valid: Maybe Bool, msg: Maybe String }

type alias Model = {
    flags : Flags
  , profile : Student.Profile.StudentProfile
  , editing : Dict String Bool
  , err_str : String
  , help : Student.Profile.Help.StudentProfileHelp
  , username_update : UsernameUpdate
  , errors : Dict String String }