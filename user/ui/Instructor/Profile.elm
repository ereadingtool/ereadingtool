module Instructor.Profile exposing (..)

import Http
import HttpHelpers

import Flags

import Instructor.Resource
import Instructor.Invite exposing (Email, InstructorInvite)

import Instructor.Invite.Encode
import Instructor.Invite.Decode

import Menu.Logout


type alias Tag = String

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
  , tags: List String
  , text_section_count: Int
  , edit_uri: String }

type alias InstructorURIParams = {
   logout_uri : String
 , profile_uri : String
 }

type alias InstructorProfileParams = {
    id: Maybe Int
  , texts: List Text
  , instructor_admin: Bool
  , invites : Maybe (List Instructor.Invite.InviteParams)
  , username: String
  , uris : InstructorURIParams }

type InstructorUsername = InstructorUsername String

type InstructorProfileURIs =
  InstructorProfileURIs Instructor.Resource.InstructorLogoutURI Instructor.Resource.InstructorProfileURI


urisToLogoutUri : InstructorProfileURIs -> Instructor.Resource.InstructorLogoutURI
urisToLogoutUri (InstructorProfileURIs logout _) =
  logout

urisToProfileUri : InstructorProfileURIs -> Instructor.Resource.InstructorProfileURI
urisToProfileUri (InstructorProfileURIs _ profile) =
  profile

type InstructorProfile =
  InstructorProfile
    (Maybe Int)
    (List Text)
    Bool
    (Maybe (List InstructorInvite))
    InstructorUsername
    InstructorProfileURIs

initProfileURIs : InstructorURIParams -> InstructorProfileURIs
initProfileURIs params =
  InstructorProfileURIs
    (Instructor.Resource.InstructorLogoutURI (Instructor.Resource.URI params.logout_uri))
    (Instructor.Resource.InstructorProfileURI (Instructor.Resource.URI params.profile_uri))


initProfile : InstructorProfileParams -> InstructorProfile
initProfile params =
  InstructorProfile
    params.id
    params.texts
    params.instructor_admin
    (case params.invites of
      Just invite_params ->
        Just (List.map Instructor.Invite.new invite_params)

      Nothing ->
        Nothing)
    (InstructorUsername params.username)
    (initProfileURIs params.uris)

addInvite : InstructorProfile -> InstructorInvite -> InstructorProfile
addInvite (InstructorProfile id texts admin invites username logout_uri) invite =
  let
    new_invites =
      (case invites of
        Just invites ->
          Just (invites ++ [invite])

        Nothing ->
          Nothing)
  in
    InstructorProfile id texts admin new_invites username logout_uri

isAdmin : InstructorProfile -> Bool
isAdmin (InstructorProfile _ _ admin _ _ _) =
  admin

invites : InstructorProfile -> Maybe (List InstructorInvite)
invites (InstructorProfile _ _ _ invites _ _) =
  invites

username : InstructorProfile -> InstructorUsername
username (InstructorProfile _ _ _ _ username _) =
  username

usernameToString : InstructorUsername -> String
usernameToString (InstructorUsername username) =
  username

uris : InstructorProfile -> InstructorProfileURIs
uris (InstructorProfile _ _ _ _ _ uris) =
  uris

logoutUri : InstructorProfile -> Instructor.Resource.InstructorLogoutURI
logoutUri instructor_profile =
  urisToLogoutUri (uris instructor_profile)

logoutUriToString : InstructorProfile -> String
logoutUriToString instructor_profile =
  Instructor.Resource.uriToString (Instructor.Resource.instructorLogoutURI (logoutUri instructor_profile))

profileUri : InstructorProfile -> Instructor.Resource.InstructorProfileURI
profileUri instructor_profile =
  urisToProfileUri (uris instructor_profile)

profileUriToString : InstructorProfile -> String
profileUriToString instructor_profile =
  Instructor.Resource.uriToString (Instructor.Resource.instructorProfileURI (profileUri instructor_profile))

texts : InstructorProfile -> List Text
texts (InstructorProfile _ texts _ _ _ _) =
  texts

logout :
     InstructorProfile
  -> Flags.CSRFToken
  -> (Result Http.Error Menu.Logout.LogOutResp -> msg)
  -> Cmd msg
logout instructor_profile csrftoken logout_msg =
  let
    request =
      HttpHelpers.post_with_headers
        (Instructor.Resource.uriToString (Instructor.Resource.instructorLogoutURI (logoutUri instructor_profile)))
        [Http.header "X-CSRFToken" csrftoken] Http.emptyBody Menu.Logout.logoutRespDecoder
  in
    Http.send logout_msg request

submitNewInvite :
     Flags.CSRFToken
  -> Instructor.Resource.InstructorInviteURI
  -> (Result Http.Error InstructorInvite -> msg)
  -> Email
  -> Cmd msg
submitNewInvite csrftoken instructor_invite_uri msg email =
  case Instructor.Invite.isValidEmail email of
    True ->
      let
        encoded_new_invite = Instructor.Invite.Encode.newInviteEncoder email

        req =
          HttpHelpers.post_with_headers
           (Instructor.Resource.uriToString (Instructor.Resource.instructorInviteURI instructor_invite_uri))
           [Http.header "X-CSRFToken" csrftoken]
           (Http.jsonBody encoded_new_invite) Instructor.Invite.Decode.newInviteRespDecoder
      in
        Http.send msg req

    False ->
      Cmd.none