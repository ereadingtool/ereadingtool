module User.Instructor.Resource exposing
    ( InstructorInviteURI
    , InstructorLogoutURI
    , InstructorProfileURI
    , URI
    , flagsToInstructorURI
    , instructorInviteURI
    , instructorLogoutURI
    , instructorProfileURI
    , toInstructorInviteURI
    , toInstructorLogoutURI
    , toInstructorProfileURI
    , uriToString
    )


type URI
    = URI String


type InstructorProfileURI
    = InstructorProfileURI URI


type InstructorLogoutURI
    = InstructorLogoutURI URI


type InstructorInviteURI
    = InstructorInviteURI URI


toURI : String -> URI
toURI uri =
    URI uri


flagsToInstructorURI : { a | instructor_invite_uri : String } -> InstructorInviteURI
flagsToInstructorURI flags =
    InstructorInviteURI (URI flags.instructor_invite_uri)


toInstructorInviteURI : String -> InstructorInviteURI
toInstructorInviteURI uri =
    InstructorInviteURI (URI uri)


instructorProfileURI : InstructorProfileURI -> URI
instructorProfileURI (InstructorProfileURI uri) =
    uri


toInstructorProfileURI : String -> InstructorProfileURI
toInstructorProfileURI uri =
    InstructorProfileURI <| toURI uri


instructorLogoutURI : InstructorLogoutURI -> URI
instructorLogoutURI (InstructorLogoutURI uri) =
    uri


toInstructorLogoutURI : String -> InstructorLogoutURI
toInstructorLogoutURI uri =
    InstructorLogoutURI <| toURI uri


instructorInviteURI : InstructorInviteURI -> URI
instructorInviteURI (InstructorInviteURI uri) =
    uri


uriToString : URI -> String
uriToString (URI uri) =
    uri
