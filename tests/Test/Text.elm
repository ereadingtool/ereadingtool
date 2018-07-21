module Test.Text exposing (..)

import Expect exposing (Expectation)
import Array

import Fuzz exposing (Fuzzer, int, list, string)

import Html
import Html.Attributes as Attr
import Dict exposing (Dict)

import Test exposing (Test, test, describe)
import Test.Html.Query as Query
import Test.Html.Selector exposing (attribute, text, tag)
import Test.Html.Event as Event

import Instructor.Profile

import Text.Component
import Text.Section.Component
import Text.Section.Component.Group exposing (TextSectionComponentGroup)

import Text.View
import Text.Section.View

import Text.Create exposing (..)

import Question.Field
import Question.Model

import Answer.Field
import Answer.Model

import Text.View
import Text.Model exposing (TextDifficulty)

import Text.Component
import Text.Section.Component.Group

type Msg = TextMsg

type alias ElementID = String
type alias ErrorMsg = String

text_difficulties : List TextDifficulty
text_difficulties = [("intermediate-mid", "Intermediate Mid"), ("advanced-low", "Advanced-Low")]

example_text_errors : Dict String String
example_text_errors =
  Dict.fromList [
      ("text_title","This field is required.")
    , ("text_introduction","This field is required.")
    , ("text_source","This field is required.")
    , ("textsection_0_body","This field is required.")
    , ("textsection_0_question_0_answer_0_feedback","This field is required.")
    , ("textsection_0_question_0_answer_1_feedback","This field is required.")
    , ("textsection_0_question_0_answer_2_feedback","This field is required.")
    , ("textsection_0_question_0_answer_3_feedback","This field is required.")
    , ("textsection_0_question_0_body","This field is required.")
    , ("textsection_0_question_0_answers","You must choose a correct answer for this question.")
  ]

test_text_component : Text.Component.TextComponent
test_text_component =
  Text.Component.emptyTextComponent

test_text_section_component_group : TextSectionComponentGroup
test_text_section_component_group =
  Text.Component.text_section_components test_text_component

test_text_section_component : Text.Section.Component.TextSectionComponent
test_text_section_component =
  Text.Section.Component.emptyTextSectionComponent 0

test_tags : Dict String String
test_tags =
  Dict.fromList [
    ("Literary Arts", "Literary Arts")
  ]

test_text_difficulties : List TextDifficulty
test_text_difficulties =
  [
    ("intermediate_mid", "Intermediate Mid")
  ]

test_profile : Instructor.Profile.InstructorProfile
test_profile =
  Instructor.Profile.init_profile {id=Just 1, username="an_instructor@ereadingtool.com"}

test_text_view_params : Text.Component.TextComponent -> TextViewParams
test_text_view_params text_component = {
    text=Text.Component.text text_component
  , text_component=text_component
  , text_fields=Text.Component.text_fields text_component
  , tags=test_tags
  , profile=test_profile
  , write_locked=False
  , mode=CreateMode
  , text_difficulties=test_text_difficulties }

test_answer_field_mutual_exclusion : Expectation
test_answer_field_mutual_exclusion =
  case Text.Section.Component.Group.text_section_component test_text_section_component_group 0 of
    Just text_section ->
      case Question.Field.get_question_field (Text.Section.Component.question_fields text_section) 0 of
        Just question_field ->
          case Answer.Field.get_answer_field (Question.Field.answers question_field) 0 of
            Just answer_field ->
              Text.Section.View.view_text_section_components (\_ -> TextMsg) test_text_section_component_group text_difficulties
                |> Query.fromHtml
                |> Query.findAll [
                   attribute <| Attr.name (Answer.Field.name answer_field)
                 , tag "input"
                 , attribute <| Attr.type_ "radio" ]
                |> Query.count (Expect.equal 4)
            _ ->
              Expect.pass
        _ ->
          Expect.pass
    _ ->
      Expect.pass

test_text_errors : Text.Component.TextComponent -> List Test
test_text_errors text_component =
  let
    html = Text.View.view_text (test_text_view_params text_component)
  in
    List.map
      (\((k, v) as err) ->
        test ("text error for " ++ k ++ " is visible") <| \() -> test_text_error html err)
      (Dict.toList example_text_errors)

test_text_error : Html.Html msg -> (ElementID, ErrorMsg) -> Expectation
test_text_error html (element_id, error_msg) =
    html
 |> Query.fromHtml
 |> Query.findAll [
      attribute <| Attr.id element_id
    , attribute <| Attr.class "input_error"
    ]
 |> Query.count (Expect.equal 1)

gen_text_component_group_with_sections : Int -> TextSectionComponentGroup
gen_text_component_group_with_sections i =
  Array.foldr
    (\i group -> add_text_section group)
    test_text_section_component_group
    (Array.repeat i 0)

test_text_section_add : Expectation
test_text_section_add =
  let
    new_group = gen_text_component_group_with_sections 5
  in
    Expect.equal 6 (Array.length <| Text.Section.Component.Group.toArray new_group)

add_text_section : TextSectionComponentGroup -> TextSectionComponentGroup
add_text_section group =
  Text.Section.Component.Group.add_new_text_section group

delete_text_section : TextSectionComponentGroup -> Text.Section.Component.TextSectionComponent -> TextSectionComponentGroup
delete_text_section group section =
  Text.Section.Component.Group.delete_text_section group section

test_text_section_update_body : Expectation
test_text_section_update_body =
  let
    group =
      Text.Section.Component.Group.update_body_for_section_index test_text_section_component_group "textsection_0_body" "foobar"
  in
    case Text.Section.Component.Group.text_section_component group 0 of
      Just section ->
        let
          text_section = Text.Section.Component.text_section section
        in
          Expect.equal "foobar" text_section.body
      _ ->
        Expect.pass

test_text_section_add_then_delete : Expectation
test_text_section_add_then_delete =
  let
    num_of_new_sections = 5
    -- simulate an update from the frontend editor
    ckeditor_id = "textsection_5_body"
    updated_text_section_body = "foobar"

    group =
      Text.Section.Component.Group.update_body_for_section_index
        (gen_text_component_group_with_sections num_of_new_sections) ckeditor_id updated_text_section_body

    text_sections = Text.Section.Component.Group.toArray group
  in
    -- delete one, and verify the section with updated_text_section_body is still around
    case Array.get 2 text_sections of
      Just text_section ->
        let
          new_group = delete_text_section group text_section
          new_group_sections = Text.Section.Component.Group.toArray new_group
        in
          Expect.equal 1
            (Array.length (Array.filter (\section ->
               (Text.Section.Component.toTextSection section).body == updated_text_section_body
            ) new_group_sections))
      _ -> Expect.pass


suite : Test
suite =
      describe "text" [
        describe "questions" [
          describe "answers" [
            test "radio buttons can be selected mutually exclusively (same name attributes)" <|
              \() -> test_answer_field_mutual_exclusion
          ]
        ]
      , describe "errors" (test_text_errors (Text.Component.update_text_errors test_text_component example_text_errors))
      , describe "text section update body" [
          test "update body for id" <| \() -> test_text_section_update_body
      ]
      , describe "text section add/delete" [
            test "add text sections" <| \() -> test_text_section_add
          , test "add then delete text sections" <| \() -> test_text_section_add_then_delete
        ]
    ]
