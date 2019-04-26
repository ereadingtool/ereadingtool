module Student.Resource exposing (..)

import Profile


type URI = URI String

type StudentEndpointURI = StudentEndpointURI URI
type StudentUsernameValidURI = StudentUsernameValidURI URI
type StudentLogoutURI = StudentLogoutURI URI


profileIDToStudentEndpointURI : StudentEndpointURI -> Profile.ProfileID -> StudentEndpointURI
profileIDToStudentEndpointURI student_endpoint_uri profile_id =
  let
    endpoint_uri = uriToString (studentEndpointURI student_endpoint_uri)
  in
    StudentEndpointURI (URI (String.join "" [endpoint_uri, (toString (Profile.profileIDtoString profile_id)) ++ "/"]))

studentEndpointURI : StudentEndpointURI -> URI
studentEndpointURI (StudentEndpointURI uri) = uri

studentUsernameValidURI : StudentUsernameValidURI -> URI
studentUsernameValidURI (StudentUsernameValidURI uri) = uri

studentLogoutURI : StudentLogoutURI -> URI
studentLogoutURI (StudentLogoutURI uri) = uri

uriToString : URI -> String
uriToString (URI uri) = uri