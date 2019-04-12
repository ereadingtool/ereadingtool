module Student.Profile.Model exposing (..)

import Dict exposing (Dict)

import Menu.Items

import Student.Profile
import Student.Profile.Flags exposing (Flags)
import Student.Profile.Help
import Student.Performance.Report

type alias UsernameUpdate = { username: String, valid: Maybe Bool, msg: Maybe String }

type alias Model = {
    flags : Flags
  , profile : Student.Profile.StudentProfile
  , menu_items : Menu.Items.MenuItems
  , performance_report : Student.Performance.Report.PerformanceReport
  , flashcards : Maybe (List String)
  , editing : Dict String Bool
  , err_str : String
  , help : Student.Profile.Help.StudentProfileHelp
  , username_update : UsernameUpdate
  , errors : Dict String String }