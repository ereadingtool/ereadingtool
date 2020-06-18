module Instructor.Resource exposing (..)


type URI
    = URI String


type InstructorProfileURI
    = InstructorProfileURI URI


type InstructorLogoutURI
    = InstructorLogoutURI URI


type InstructorInviteURI
    = InstructorInviteURI URI


flagsToInstructorURI : { a | instructor_invite_uri : String } -> InstructorInviteURI
flagsToInstructorURI flags =
    InstructorInviteURI (URI flags.instructor_invite_uri)


instructorProfileURI : InstructorProfileURI -> URI
instructorProfileURI (InstructorProfileURI uri) =
    uri


instructorLogoutURI : InstructorLogoutURI -> URI
instructorLogoutURI (InstructorLogoutURI uri) =
    uri


instructorInviteURI : InstructorInviteURI -> URI
instructorInviteURI (InstructorInviteURI uri) =
    uri


uriToString : URI -> String
uriToString (URI uri) =
    uri
