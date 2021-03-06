module User.Instructor.Invite exposing
    ( Email(..)
    , InstructorInvite(..)
    , InviteCode(..)
    , InviteExpiration(..)
    , InviteParams
    , codeToString
    , email
    , emailToString
    , expirationToPosix
    , inviteCode
    , inviteExpiration
    , isEmptyEmail
    , isValidEmail
    , new
    )

import Time exposing (Posix)
import Utils


type alias InviteParams =
    { email : String
    , invite_code : String
    , expiration : Posix
    }


type Email
    = Email String


type InviteCode
    = InviteCode String


type InviteExpiration
    = InviteExpiration Posix


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
email (InstructorInvite eml _ _) =
    eml


expirationToPosix : InviteExpiration -> Posix
expirationToPosix (InviteExpiration exp) =
    exp


codeToString : InviteCode -> String
codeToString (InviteCode code) =
    code


emailToString : Email -> String
emailToString (Email eml) =
    eml


isValidEmail : Email -> Bool
isValidEmail eml =
    Utils.isValidEmail (emailToString eml)


isEmptyEmail : Email -> Bool
isEmptyEmail eml =
    emailToString eml == ""
