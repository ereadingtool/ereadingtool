module Student.Profile.Flags exposing (..)

import Flags
import Student.Profile

import Student.Performance.Report

type alias Flags = {
    csrftoken : Flags.CSRFToken
  , student_profile : Student.Profile.StudentProfileParams
  , flashcards : Maybe (List String)
  , performance_report : Student.Performance.Report.PerformanceReport
  , welcome: Bool }