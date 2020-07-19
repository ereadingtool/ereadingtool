module Instructor.Profile.Msg exposing (Msg(..))

import Http
import Instructor.Invite
import Menu.Logout
import Menu.Msg as MenuMsg



-- UPDATE


type Msg
    = UpdateNewInviteEmail Instructor.Invite.Email
    | SubmittedNewInvite (Result Http.Error Instructor.Invite.InstructorInvite)
    | SubmitNewInvite
    | LogOut MenuMsg.Msg
    | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)
