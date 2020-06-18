module Instructor.Invite exposing (..)

import Util


type alias InviteParams =
    { email : String
    , invite_code : String
    , expiration : String
    }


type Email
    = Email String


type InviteCode
    = InviteCode String


type InviteExpiration
    = InviteExpiration String


type InstructorInvite
    = InstructorInvite Email InviteCode InviteExpiration


new : InviteParams -> InstructorInvite
new params =
    InstructorInvite (Email params.email) (InviteCode params.invite_code) (InviteExpiration params.expiration)


inviteExpiration : InstructorInvite -> InviteExpiration
inviteExpiration (InstructorInvite _ _ invite_exp) =
    invite_exp


inviteCode : InstructorInvite -> InviteCode
inviteCode (InstructorInvite _ invite_code _) =
    invite_code


email : InstructorInvite -> Email
email (InstructorInvite email _ _) =
    email


expirationToString : InviteExpiration -> String
expirationToString (InviteExpiration exp) =
    exp


codeToString : InviteCode -> String
codeToString (InviteCode code) =
    code


emailToString : Email -> String
emailToString (Email email) =
    email


isValidEmail : Email -> Bool
isValidEmail email =
    Util.isValidEmail (emailToString email)


isEmptyEmail : Email -> Bool
isEmptyEmail email =
    emailToString email == ""
