module User.Instructor.Profile.Msg exposing (Msg(..))

import Http
import Menu.Logout
import Menu.Msg as MenuMsg
import User.Instructor.Invite exposing (Email, InstructorInvite)



-- UPDATE


type Msg
    = UpdateNewInviteEmail Email
    | SubmittedNewInvite (Result Http.Error InstructorInvite)
    | SubmitNewInvite
    | LogOut MenuMsg.Msg
    | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)
