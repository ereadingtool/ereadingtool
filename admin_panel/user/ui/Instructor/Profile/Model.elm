module Instructor.Profile.Model exposing (Model)

import Dict exposing (Dict)

import Instructor.Profile
import Instructor.Profile.Flags
import Instructor.Resource

import Instructor.Invite

import Menu.Items


type alias Model = {
    flags : Instructor.Profile.Flags.Flags
  , profile : Instructor.Profile.InstructorProfile
  , instructor_invite_uri : Instructor.Resource.InstructorInviteURI
  , menu_items : Menu.Items.MenuItems
  , new_invite_email : Maybe Instructor.Invite.Email
  , errors : Dict String String }