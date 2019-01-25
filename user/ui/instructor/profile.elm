module Instructor.Profile exposing (..)

import Http
import HttpHelpers

import Config exposing (..)

import Menu.Logout

type alias Tag = String
type alias URI = String

type alias Text = {
    id: Int
  , title: String
  , introduction: String
  , author: String
  , source: String
  , difficulty: String
  , conclusion: Maybe String
  , created_by: String
  , last_modified_by: Maybe String
  , tags: Maybe (List String)
  , created_dt: String
  , modified_dt: String
  , write_locker: Maybe String
  , tags: List Tag
  , text_section_count: Int
  , edit_uri: URI }

type alias Invite = {
    email: String
  , invite_code: String
  , expiration: String }

type alias InstructorProfileParams = {
    id: Maybe Int
  , texts: List Text
  , invites : Maybe (List Invite)
  , username: String }

type InstructorProfile = InstructorProfile InstructorProfileParams

init_profile : InstructorProfileParams -> InstructorProfile
init_profile params =
  InstructorProfile params

addInvite : InstructorProfile -> Invite -> InstructorProfile
addInvite instructor_profile invite =
  let
    new_attrs = attrs instructor_profile

    new_invites =
      (case invites instructor_profile of
        Just invites ->
          Just (invites ++ [invite])

        Nothing ->
          Nothing)
  in
    InstructorProfile { new_attrs | invites = new_invites }

inviteURI : String
inviteURI =
  Config.instructor_invite_uri

invites : InstructorProfile -> Maybe (List Invite)
invites instructor_profile =
  (attrs instructor_profile).invites

username : InstructorProfile -> String
username instructor_profile =
  (attrs instructor_profile).username

attrs : InstructorProfile -> InstructorProfileParams
attrs (InstructorProfile attrs) = attrs

texts : InstructorProfile -> List Text
texts instructor_profile =
  (attrs instructor_profile).texts

logout : InstructorProfile -> String -> (Result Http.Error Menu.Logout.LogOutResp -> msg) -> Cmd msg
logout instructor_profile csrftoken logout_msg =
  let
    request =
      HttpHelpers.post_with_headers
        Config.instructor_logout_api_endpoint
        [Http.header "X-CSRFToken" csrftoken] Http.emptyBody Menu.Logout.logoutRespDecoder
  in
    Http.send logout_msg request