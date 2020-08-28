module User.Instructor.Profile exposing
    ( InstructorProfile
    , InstructorProfileParams
    , Tag
    , Text
    , addInvite
    , initProfile
    , invites
    , isAdmin
    , logout
    , profileUriToString
    , submitNewInvite
    , texts
    , username
    , usernameToString
    )

import Flags
import Http
import Menu.Logout
import User.Instructor.Invite as InstructorInvite exposing (Email, InstructorInvite)
import User.Instructor.Invite.Decode as InstructorInviteDecode
import User.Instructor.Invite.Encode as InstructorInviteEncode
import User.Instructor.Resource as InstructorResource


type alias Tag =
    String


type alias Text =
    { id : Int
    , title : String
    , introduction : String
    , author : String
    , source : String
    , difficulty : String
    , conclusion : Maybe String
    , created_by : String
    , last_modified_by : Maybe String
    , created_dt : String
    , modified_dt : String
    , write_locker : Maybe String
    , tags : List String
    , text_section_count : Int
    , edit_uri : String
    }


type alias InstructorURIParams =
    { logout_uri : String
    , profile_uri : String
    }


type alias InstructorProfileParams =
    { id : Maybe Int
    , texts : List Text
    , instructor_admin : Bool
    , invites : Maybe (List InstructorInvite.InviteParams)
    , username : String
    , uris : InstructorURIParams
    }


type InstructorUsername
    = InstructorUsername String


type InstructorProfileURIs
    = InstructorProfileURIs InstructorResource.InstructorLogoutURI InstructorResource.InstructorProfileURI


urisToLogoutUri : InstructorProfileURIs -> InstructorResource.InstructorLogoutURI
urisToLogoutUri (InstructorProfileURIs logout_uri _) =
    logout_uri


urisToProfileUri : InstructorProfileURIs -> InstructorResource.InstructorProfileURI
urisToProfileUri (InstructorProfileURIs _ profile) =
    profile


type InstructorProfile
    = InstructorProfile (Maybe Int) (List Text) Bool (Maybe (List InstructorInvite)) InstructorUsername InstructorProfileURIs


initProfileURIs : InstructorURIParams -> InstructorProfileURIs
initProfileURIs params =
    InstructorProfileURIs
        (InstructorResource.toInstructorLogoutURI params.logout_uri)
        (InstructorResource.toInstructorProfileURI params.profile_uri)


initProfile : InstructorProfileParams -> InstructorProfile
initProfile param =
    InstructorProfile
        param.id
        param.texts
        param.instructor_admin
        (param.invites
            |> Maybe.map (List.map InstructorInvite.new)
        )
        (InstructorUsername param.username)
        (initProfileURIs param.uris)


addInvite : InstructorProfile -> InstructorInvite -> InstructorProfile
addInvite (InstructorProfile id ts admin invitations uname logout_uri) invite =
    let
        new_invites =
            Maybe.map (\i -> i ++ [ invite ]) invitations
    in
    InstructorProfile id ts admin new_invites uname logout_uri


isAdmin : InstructorProfile -> Bool
isAdmin (InstructorProfile _ _ admin _ _ _) =
    admin


invites : InstructorProfile -> Maybe (List InstructorInvite)
invites (InstructorProfile _ _ _ invitations _ _) =
    invitations


username : InstructorProfile -> InstructorUsername
username (InstructorProfile _ _ _ _ uname _) =
    uname


usernameToString : InstructorUsername -> String
usernameToString (InstructorUsername uname) =
    uname


uris : InstructorProfile -> InstructorProfileURIs
uris (InstructorProfile _ _ _ _ _ instructorUris) =
    instructorUris


logoutUri : InstructorProfile -> InstructorResource.InstructorLogoutURI
logoutUri instructor_profile =
    urisToLogoutUri (uris instructor_profile)


logoutUriToString : InstructorProfile -> String
logoutUriToString instructor_profile =
    InstructorResource.uriToString (InstructorResource.instructorLogoutURI (logoutUri instructor_profile))


profileUri : InstructorProfile -> InstructorResource.InstructorProfileURI
profileUri instructor_profile =
    urisToProfileUri (uris instructor_profile)


profileUriToString : InstructorProfile -> String
profileUriToString instructor_profile =
    InstructorResource.uriToString (InstructorResource.instructorProfileURI (profileUri instructor_profile))


texts : InstructorProfile -> List Text
texts (InstructorProfile _ instructorTexts _ _ _ _) =
    instructorTexts


logout :
    InstructorProfile
    -> Flags.CSRFToken
    -> (Result Http.Error Menu.Logout.LogOutResp -> msg)
    -> Cmd msg
logout instructor_profile csrftoken logout_msg =
    let
        request =
            Debug.todo

        -- HttpHelpers.post_with_headers
        --     (InstructorResource.uriToString (InstructorResource.instructorLogoutURI (logoutUri instructor_profile)))
        --     [ Http.header "X-CSRFToken" csrftoken ]
        --     Http.emptyBody
        --     Menu.Logout.logoutRespDecoder
    in
    -- Http.send logout_msg request
    Debug.todo "instructor logout"


submitNewInvite :
    Flags.CSRFToken
    -> InstructorResource.InstructorInviteURI
    -> (Result Http.Error InstructorInvite -> msg)
    -> Email
    -> Cmd msg
submitNewInvite csrftoken instructor_invite_uri msg email =
    if InstructorInvite.isValidEmail email then
        let
            encoded_new_invite =
                InstructorInviteEncode.newInviteEncoder email

            req =
                Debug.todo

            -- HttpHelpers.post_with_headers
            --     (InstructorResource.uriToString (InstructorResource.instructorInviteURI instructor_invite_uri))
            --     [ Http.header "X-CSRFToken" csrftoken ]
            --     (Http.jsonBody encoded_new_invite)
            --     InstructorInviteDecode.newInviteRespDecoder
        in
        -- Http.send msg req
        Debug.todo "instructor submit new invite"

    else
        Cmd.none
