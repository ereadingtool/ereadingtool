module Tests.Quiz exposing (..)

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

import Quiz.Component
import Quiz.View
import Quiz.Create exposing (..)

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

example_quiz_errors : Dict String String
example_quiz_errors =
  Dict.fromList [
  -- quiz
    ("quiz_title", "This field is required.")
  , ("quiz_introduction", "An introduction is required.")
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

test_quiz_component : Quiz.Component.QuizComponent
test_quiz_component =
  Quiz.Component.emptyQuizComponent

test_text_component_group : Text.Component.Group.TextComponentGroup
test_text_component_group =
  Quiz.Component.text_components test_quiz_component

test_tags : Dict String String
test_tags =
  Dict.fromList [
    ("Litrary Arts", "Literary Arts")
  ]

test_profile : Instructor.Profile.InstructorProfile
test_profile =
  Instructor.Profile.init_profile {id=Just 1, username="an_instructor@ereadingtool.com"}

test_quiz_view_params : Quiz.Component.QuizComponent -> QuizViewParams
test_quiz_view_params quiz_component = {
    quiz=Quiz.Component.quiz quiz_component
  , quiz_component=quiz_component
  , quiz_fields=Quiz.Component.quiz_fields quiz_component
  , tags=test_tags
  , profile=test_profile
  , write_locked=False
  , mode=CreateMode }

test_answer_field_mutual_exclusion : Expectation
test_answer_field_mutual_exclusion =
  case Text.Component.Group.text_component test_text_component_group 0 of
    Just component ->
      case Question.Field.get_question_field (Text.Component.question_fields component) 0 of
        Just question_field ->
          case Answer.Field.get_answer_field (Question.Field.answers question_field) 0 of
            Just answer_field ->
              Text.View.view_text_components (\_ -> TextMsg) test_text_component_group text_difficulties
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

test_quiz_errors : Quiz.Component.QuizComponent -> List Test
test_quiz_errors quiz_component =
  let
    html = Quiz.View.view_quiz (test_quiz_view_params quiz_component)
  in
    List.map
      (\((k, v) as err) ->
        test ("quiz error for " ++ k ++ " is visible") <| \() -> test_quiz_error html err)
      (Dict.toList example_quiz_errors)

test_quiz_error : Html.Html msg -> (ElementID, ErrorMsg) -> Expectation
test_quiz_error html (element_id, error_msg) =
    html
 |> Query.fromHtml
 |> Query.findAll [
      attribute <| Attr.id element_id
    , attribute <| Attr.class "input_error"
    ]
 |> Query.count (Expect.equal 1)


suite : Test
suite =
      describe "quiz" [
        describe "questions" [
          describe "answers" [
            test "radio buttons can be selected mutually exclusively (same name attributes)" <|
              \() -> test_answer_field_mutual_exclusion
          ]
        ]
      , describe "errors" (test_quiz_errors (Quiz.Component.update_quiz_errors test_quiz_component example_quiz_errors))
    ]
