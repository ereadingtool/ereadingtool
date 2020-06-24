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
import Student.Resource exposing (..)


type alias UsernameUpdate =
    { username : Maybe Student.Resource.StudentUsername
    , valid : Maybe Bool
    , msg : Maybe String
    }


type alias StudentConsentResp =
    { consented : Bool }


type alias StudentEndpoints =
    { student_endpoint_uri : StudentEndpointURI
    , student_research_consent_uri : StudentResearchConsentURI
    , student_username_validation_uri : StudentUsernameValidURI
    }


flagsToEndpoints : Flags -> StudentEndpoints
flagsToEndpoints flags =
    StudentEndpoints
        (StudentEndpointURI (URI flags.student_endpoint))
        (StudentResearchConsentURI (URI flags.student_research_consent_uri))
        (StudentUsernameValidURI (URI flags.student_username_validation_uri))


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
