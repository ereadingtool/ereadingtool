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
