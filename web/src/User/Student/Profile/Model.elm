module User.Student.Profile.Model exposing
    ( Model
    , StudentConsentResp
    , UsernameUpdate
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


type alias Model =
    { flags : Flags
    , profile : StudentProfile
    , menu_items : Menu.Items.MenuItems
    , performance_report : PerformanceReport
    , consenting_to_research : Bool
    , flashcards : Maybe (List String)
    , editing : Dict String Bool
    , err_str : String
    , help : StudentProfileHelp.StudentProfileHelp
    , username_update : UsernameUpdate
    , errors : Dict String String
    }
