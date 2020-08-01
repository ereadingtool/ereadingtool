module User.Student.Resource exposing
    ( StudentEmail
    , StudentEndpointURI
    , StudentLogoutURI
    , StudentProfileURI
    , StudentResearchConsentURI
    , StudentUsername
    , StudentUsernameValidURI
    , URI
    , studentConsentURI
    , studentEmailToString
    , studentEndpointURI
    , studentLogoutURI
    , studentProfileURI
    , studentUserNameToString
    , studentUsernameValidURI
    , toStudentEmail
    , toStudentEndpointURI
    , toStudentLogoutURI
    , toStudentProfileURI
    , toStudentResearchConsentURI
    , toStudentUsername
    , toStudentUsernameValidURI
    , uriToString
    )

import User.Profile as Profile


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


toStudentEndpointURI : String -> StudentEndpointURI
toStudentEndpointURI endpointURI =
    StudentEndpointURI (URI endpointURI)


toStudentResearchConsentURI : String -> StudentResearchConsentURI
toStudentResearchConsentURI consentURI =
    StudentResearchConsentURI (URI consentURI)


toStudentUsernameValidURI : String -> StudentUsernameValidURI
toStudentUsernameValidURI userValidURI =
    StudentUsernameValidURI (URI userValidURI)


toStudentProfileURI : String -> StudentProfileURI
toStudentProfileURI profileURI =
    StudentProfileURI (URI profileURI)


toStudentLogoutURI : String -> StudentLogoutURI
toStudentLogoutURI logoutURI =
    StudentLogoutURI (URI logoutURI)


toStudentEmail : String -> StudentEmail
toStudentEmail email =
    StudentEmail email


toStudentUsername : String -> StudentUsername
toStudentUsername userName =
    StudentUsername userName


studentEmailToString : StudentEmail -> String
studentEmailToString (StudentEmail email) =
    email


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
