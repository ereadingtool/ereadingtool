module Student.Resource exposing
    ( StudentEndpointURI
    , StudentLogoutURI
    , StudentProfileURI
    , StudentResearchConsentURI
    , StudentUsername
    , StudentUsernameValidURI
    , URI
    , studentConsentURI
    , studentEndpointURI
    , studentLogoutURI
    , studentProfileURI
    , studentUserNameToString
    , studentUsernameValidURI
    , uriToString
    )

import Profile


type URI
    = URI String


type StudentEndpointURI
    = StudentEndpointURI URI


type StudentResearchConsentURI
    = StudentResearchConsentURI URI


type StudentUsernameValidURI
    = StudentUsernameValidURI URI


type StudentLogoutURI
    = StudentLogoutURI URI


type StudentProfileURI
    = StudentProfileURI URI


type StudentEmail
    = StudentEmail String


type StudentUsername
    = StudentUsername String


studentUserNameToString : StudentUsername -> String
studentUserNameToString (StudentUsername username) =
    username


profileIDToStudentEndpointURI : StudentEndpointURI -> Profile.ProfileID -> StudentEndpointURI
profileIDToStudentEndpointURI student_endpoint_uri profileID =
    let
        endpointURI =
            uriToString (studentEndpointURI student_endpoint_uri)
    in
    StudentEndpointURI (URI (String.join "" [ endpointURI, Profile.profileIDtoString profileID ++ "/" ]))


studentProfileURI : StudentProfileURI -> URI
studentProfileURI (StudentProfileURI uri) =
    uri


studentEndpointURI : StudentEndpointURI -> URI
studentEndpointURI (StudentEndpointURI uri) =
    uri


studentConsentURI : StudentResearchConsentURI -> URI
studentConsentURI (StudentResearchConsentURI uri) =
    uri


studentUsernameValidURI : StudentUsernameValidURI -> URI
studentUsernameValidURI (StudentUsernameValidURI uri) =
    uri


studentLogoutURI : StudentLogoutURI -> URI
studentLogoutURI (StudentLogoutURI uri) =
    uri


uriToString : URI -> String
uriToString (URI uri) =
    uri
