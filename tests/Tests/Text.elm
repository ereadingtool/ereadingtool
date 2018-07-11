module Tests.Text exposing (..)

import Expect exposing (Expectation)
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
import Text.View
import Text.Create exposing (..)

import Question.Field
import Question.Model

import Answer.Field
import Answer.Model

import Text.View
import Text.Model exposing (TextDifficulty)

import Text.Component
import Text.Component.Group

type Msg = TextMsg

type alias ElementID = String
type alias ErrorMsg = String

text_difficulties : List TextDifficulty
text_difficulties = [("intermediate-mid", "Intermediate Mid"), ("advanced-low", "Advanced-Low")]

example_text_errors : Dict String String
example_text_errors =
  Dict.fromList [
  -- text
    ("text_title", "This field is required.")
  , ("text_introduction", "An introduction is required.")
  -- texts
  , ("text_0_title", "A title is required.")
  , ("text_0_source", "A source is required.")
  , ("text_0_difficulty", "A difficulty is required.")
  , ("text_0_author", "An author is required.")
  , ("text_0_body", "A text body is required.")
  -- questions/answers
  , ("text_0_question_0_answer_0", "An answer text is required.")
  , ("text_0_question_0_answer_0_feedback", "Feedback is required.")
  ]

test_text_component : Text.Component.TextComponent
test_text_component =
  Text.Component.emptyTextComponent

test_text_component_group : Text.Component.Group.TextComponentGroup
test_text_component_group =
  Text.Component.text_section_components test_text_component

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
  case Text.Component.Group.text_component test_text_component_group 0 of
    Just component ->
      case Question.Field.get_question_field (Text.Component.question_fields component) 0 of
        Just question_field ->
          case Answer.Field.get_answer_field (Question.Field.answers question_field) 0 of
            Just answer_field ->
              Text.View.view_text_section_components (\_ -> TextMsg) test_text_component_group text_difficulties
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
    ]
