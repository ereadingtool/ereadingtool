module Student.Profile.Msg exposing (Msg, Msg(..))

import Http exposing (..)

import Student.Profile
import Student.Profile.Model
import Student.Profile.Help

import Menu.Msg as MenuMsg
import Menu.Logout


-- UPDATE
type Msg =
    RetrieveStudentProfile (Result Error Student.Profile.StudentProfile)
  -- preferred difficulty
  | UpdateDifficulty String
  -- username
  | ToggleUsernameUpdate
  | ValidUsername (Result Error Student.Profile.Model.UsernameUpdate)
  | UpdateUsername String
  | SubmitUsernameUpdate
  | CancelUsernameUpdate
  -- profile update submission
  | Submitted (Result Error Student.Profile.StudentProfile)
  -- help messages
  | CloseHelp Student.Profile.Help.HelpMsg
  -- site-wide messages
  | Logout MenuMsg.Msg
  | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)