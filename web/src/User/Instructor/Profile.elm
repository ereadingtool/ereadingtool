module User.Instructor.Profile exposing
    ( InstructorProfile(..)
    , InstructorProfileParams
    , InstructorUsername(..)
    , Tag
    , Text
    , addInvite
    , decoder
    , initProfile
    , initProfileURIs
    , invites
    , isAdmin
    , profileUriToString
    , texts
    , username
    , usernameToString
    )

import Iso8601
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Time exposing (Posix)
import User.Instructor.Invite as InstructorInvite exposing (InstructorInvite)
import User.Instructor.Resource as InstructorResource


type alias Tag =
    String


type alias Text =
    { id : Int
    , title : String
    , author : String
    , difficulty : String
    , created_by : String
    , created_dt : String
    , modified_dt : String
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
    , username : String
    , instructor_admin : Bool
    , invites : Maybe (List InstructorInvite.InviteParams)
    , texts : List Text
    , uris : InstructorURIParams
    }


type alias InviteParams =
    { email : String
    , invite_code : String
    , expiration : Posix
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
            Maybe.map
                (\invs ->
                    invite
                        :: List.filter (\inv -> InstructorInvite.email inv /= InstructorInvite.email invite) invs
                )
                invitations
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



-- DECODE


decoder : Decoder InstructorProfile
decoder =
    Decode.field "profile" paramsDecoder
        |> Decode.map initProfile


paramsDecoder : Decoder InstructorProfileParams
paramsDecoder =
    Decode.succeed InstructorProfileParams
        |> required "id" (Decode.nullable Decode.int)
        |> required "username" Decode.string
        |> required "instructor_admin" Decode.bool
        |> required "invites" (Decode.nullable (Decode.list inviteDecoder))
        |> required "texts" (Decode.list textDecoder)
        |> required "uris" uriParamsDecoder


textDecoder : Decoder Text
textDecoder =
    Decode.succeed Text
        |> required "id" Decode.int
        |> required "title" Decode.string
        |> required "author" Decode.string
        |> required "difficulty" Decode.string
        |> required "created_by" Decode.string
        |> required "created_dt" Decode.string
        |> required "modified_dt" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "text_section_count" Decode.int
        |> required "edit_uri" Decode.string


inviteDecoder : Decoder InviteParams
inviteDecoder =
    Decode.succeed InviteParams
        |> required "email" Decode.string
        |> required "invite_code" Decode.string
        |> required "expiration" Iso8601.decoder


uriParamsDecoder : Decoder InstructorURIParams
uriParamsDecoder =
    Decode.succeed InstructorURIParams
        |> required "logout_uri" Decode.string
        |> required "profile_uri" Decode.string
