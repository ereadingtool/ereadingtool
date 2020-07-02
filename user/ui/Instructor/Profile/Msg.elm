module Instructor.Profile.Msg exposing (Msg(..))

import Menu.Msg as MenuMsg
import Instructor.Invite

import Http
import Menu.Logout


-- UPDATE
type Msg =
   UpdateNewInviteEmail Instructor.Invite.Email
 | SubmittedNewInvite (Result Http.Error Instructor.Invite.InstructorInvite)
 | SubmitNewInvite
 | LogOut MenuMsg.Msg
 | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)
