module Test.User.Instructor.Profile exposing (..)

import Dict exposing (Dict)

import Expect exposing (Expectation)

import Instructor.Profile

import Instructor.Profile.Init
import Instructor.Profile.View
import Instructor.Profile.Flags
import Instructor.Profile.Model

import Html exposing (..)
import Html.Attributes exposing (class, classList)

import VirtualDom
import HtmlParser
import HtmlParser.Util

import Test exposing (Test, test, describe)

import Test.Html.Query as Query

import Html.Attributes

import Test.Html.Selector


initInstructorProfileParams : Bool -> Instructor.Profile.InstructorProfileParams
initInstructorProfileParams is_admin =
  Instructor.Profile.InstructorProfileParams
    Nothing
    []
    is_admin
    Nothing
    "ereader@pdx.edu"
    {logout_uri = "/instructor/logout", profile_uri = "/instructor/profile"}


instructorFlags : Instructor.Profile.InstructorProfileParams -> Instructor.Profile.Flags.Flags
instructorFlags profile_params =
  { csrftoken = "test"
      , menu_items = []
      , instructor_invite_uri = "/instructor/invite"
      , instructor_profile = profile_params}

initModel : Instructor.Profile.Flags.Flags -> Instructor.Profile.Model.Model
initModel flags =
  let
    (model, _) = Instructor.Profile.Init.init flags
  in
    model

test_instructor_has_invite_html : Expectation
test_instructor_has_invite_html =
  let
    model = initModel (instructorFlags (initInstructorProfileParams True))
  in
     Instructor.Profile.View.view_content model
  |> Query.fromHtml
  |> Query.find [ Test.Html.Selector.id "create_invite" ]
  |> Query.children [ Test.Html.Selector.id "input" ]
  |> Query.count (Expect.equal 1)


test_instructors_do_not_have_invite_html : Expectation
test_instructors_do_not_have_invite_html =
  let
    model = initModel (instructorFlags (initInstructorProfileParams False))
  in
     Instructor.Profile.View.view_content model
  |> Query.fromHtml
  |> Query.findAll [ Test.Html.Selector.id "create_invite" ]
  |> Query.count (Expect.equal 0)


suite : Test
suite =
  describe "instructor profile" [
    test "admin instructor has invite html" <| \() -> test_instructor_has_invite_html
  , test "regular instructors do not have invite html" <| \() -> test_instructors_do_not_have_invite_html
  ]