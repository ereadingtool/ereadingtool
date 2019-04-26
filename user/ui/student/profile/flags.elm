module Student.Profile.Flags exposing (..)

import Flags
import Student.Profile

import Student.Performance.Report

type alias Flags = Flags.AuthedFlags {
    student_profile : Student.Profile.StudentProfileParams
  , student_endpoint : String
  , student_username_validation_uri : String
  , flashcards : Maybe (List String)
  , performance_report : Student.Performance.Report.PerformanceReport
  , consenting_to_research : Bool
  , welcome: Bool }