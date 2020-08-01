module User.Student.Profile.Flags exposing (Flags)

import Flags
import User.Student.Performance.Report exposing (PerformanceReport)
import User.Student.Profile exposing (StudentProfileParams)


type alias Flags =
    Flags.AuthedFlags
        { student_profile : StudentProfileParams
        , student_endpoint : String
        , student_research_consent_uri : String
        , student_username_validation_uri : String
        , flashcards : Maybe (List String)
        , performance_report : PerformanceReport
        , consenting_to_research : Bool
        , welcome : Bool
        }
