module Instructor.Resource exposing (..)

import Profile

type URI = URI String

type InstructorLogoutURI = InstructorLogoutURI URI


instructorLogoutURI : InstructorLogoutURI -> URI
instructorLogoutURI (InstructorLogoutURI uri) = uri

uriToString : URI -> String
uriToString (URI uri) = uri