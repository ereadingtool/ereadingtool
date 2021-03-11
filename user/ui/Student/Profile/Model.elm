module Student.Profile.Model exposing
    ( Model
    , StudentConsentResp
    , UsernameUpdate
    , flagsToEndpoints
    )

import Dict exposing (Dict)
import Menu.Items
import Student.Performance.Report
import Student.Profile
import Student.Profile.Flags exposing (Flags)
import Student.Profile.Help
import Student.Resource


type alias UsernameUpdate =
    { username : Maybe Student.Resource.StudentUsername
    , valid : Maybe Bool
    , msg : Maybe String
    }


type alias StudentConsentResp =
    { consented : Bool }


type alias StudentEndpoints =
    { student_endpoint_uri : Student.Resource.StudentEndpointURI
    , student_research_consent_uri : Student.Resource.StudentResearchConsentURI
    , student_username_validation_uri : Student.Resource.StudentUsernameValidURI
    }


flagsToEndpoints : Flags -> StudentEndpoints
flagsToEndpoints flags =
    StudentEndpoints
        (Student.Resource.toStudentEndpointURI flags.student_endpoint)
        (Student.Resource.toStudentResearchConsentURI flags.student_research_consent_uri)
        (Student.Resource.toStudentUsernameValidURI flags.student_username_validation_uri)


type alias Model =
    { flags : Flags
    , profile : Student.Profile.StudentProfile
    , menu_items : Menu.Items.MenuItems
    , performance_report : Student.Performance.Report.PerformanceReport
    , student_endpoints : StudentEndpoints
    , consenting_to_research : Bool
    , flashcards : Maybe (List String)
    , editing : Dict String Bool
    , err_str : String
    , help : Student.Profile.Help.StudentProfileHelp
    , username_update : UsernameUpdate
    , errors : Dict String String
    }
