module Student.Profile.Msg exposing (Msg, Msg(..), HelpMsgs)

import Http exposing (..)

import Student.Profile
import Student.Profile.Model
import Student.Profile.Help

import Menu.Msg as MenuMsg
import Menu.Logout


type alias HelpMsgs msg = {
   next: msg
 , prev: msg
 , close: (Student.Profile.Help.StudentHelp -> msg) }

-- UPDATE

type Msg =
    RetrieveStudentProfile (Result Error Student.Profile.StudentProfile)
  -- preferred difficulty
  | UpdateDifficulty String
  -- username
  | ToggleUsernameUpdate
  | ToggleResearchConsent
  | ValidUsername (Result Error Student.Profile.Model.UsernameUpdate)
  | UpdateUsername String
  | SubmitUsernameUpdate
  | CancelUsernameUpdate
  -- profile update submission
  | Submitted (Result Error Student.Profile.StudentProfile)
  | SubmittedConsent (Result Error Student.Profile.Model.StudentConsentResp)
  -- help messages
  | CloseHelp Student.Profile.Help.StudentHelp
  | PrevHelp
  | NextHelp
  -- site-wide messages
  | Logout MenuMsg.Msg
  | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)