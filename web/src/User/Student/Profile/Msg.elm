module User.Student.Profile.Msg exposing (HelpMsgs, Msg(..))

import Http exposing (..)
import Menu.Logout
import Menu.Msg as MenuMsg
import User.Student.Profile exposing (StudentProfile)
import User.Student.Profile.Help as StudentProfileHelp
import User.Student.Profile.Model as StudentProfileModel


type alias HelpMsgs msg =
    { next : msg
    , prev : msg
    , close : StudentProfileHelp.StudentHelp -> msg
    }



-- UPDATE


type Msg
    = RetrieveStudentProfile (Result Error StudentProfile)
      -- preferred difficulty
    | UpdateDifficulty String
      -- username
    | ToggleUsernameUpdate
    | ToggleResearchConsent
    | ValidUsername (Result Error StudentProfileModel.UsernameUpdate)
    | UpdateUsername String
    | SubmitUsernameUpdate
    | CancelUsernameUpdate
      -- profile update submission
    | Submitted (Result Error StudentProfile)
    | SubmittedConsent (Result Error StudentProfileModel.StudentConsentResp)
      -- help messages
    | CloseHelp StudentProfileHelp.StudentHelp
    | PrevHelp
    | NextHelp
      -- site-wide messages
    | Logout MenuMsg.Msg
    | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)
