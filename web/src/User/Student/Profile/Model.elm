module User.Student.Profile.Model exposing
    ( Model
    , StudentConsentResp
    , UsernameUpdate
    , flagsToEndpoints
    )

import Dict exposing (Dict)
import Menu.Items
import User.Student.Performance.Report exposing (PerformanceReport)
import User.Student.Profile exposing (StudentProfile)
import User.Student.Profile.Flags exposing (Flags)
import User.Student.Profile.Help as StudentProfileHelp
import User.Student.Resource as StudentResource


type alias UsernameUpdate =
    { username : Maybe StudentResource.StudentUsername
    , valid : Maybe Bool
    , msg : Maybe String
    }


type alias StudentConsentResp =
    { consented : Bool }


type alias StudentEndpoints =
    { student_endpoint_uri : StudentResource.StudentEndpointURI
    , student_research_consent_uri : StudentResource.StudentResearchConsentURI
    , student_username_validation_uri : StudentResource.StudentUsernameValidURI
    }


flagsToEndpoints : Flags -> StudentEndpoints
flagsToEndpoints flags =
    StudentEndpoints
        (StudentResource.toStudentEndpointURI flags.student_endpoint)
        (StudentResource.toStudentResearchConsentURI flags.student_research_consent_uri)
        (StudentResource.toStudentUsernameValidURI flags.student_username_validation_uri)


type alias Model =
    { flags : Flags
    , profile : StudentProfile
    , menu_items : Menu.Items.MenuItems
    , performance_report : PerformanceReport
    , student_endpoints : StudentEndpoints
    , consenting_to_research : Bool
    , flashcards : Maybe (List String)
    , editing : Dict String Bool
    , err_str : String
    , help : StudentProfileHelp.StudentProfileHelp
    , username_update : UsernameUpdate
    , errors : Dict String String
    }
