module Tests.Quiz exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)

import Html
import Html.Attributes as Attr

import Test exposing (test, describe)
import Test.Html.Query as Query
import Test.Html.Selector exposing (attribute, text, tag)
import Test.Html.Event as Event

import Quiz.Component

import Question.Field
import Question.Model

import Answer.Field
import Answer.Model

import Text.View
import Text.Model exposing (TextDifficulty)

import Text.Component
import Text.Component.Group

type Msg = TextMsg

test_quiz_component : Quiz.Component.QuizComponent
test_quiz_component =
  Quiz.Component.emptyQuizComponent

test_text_component_group : Text.Component.Group.TextComponentGroup
test_text_component_group =
  Quiz.Component.text_components test_quiz_component

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

text_difficulties : List TextDifficulty
text_difficulties = [("intermediate-mid", "Intermediate Mid"), ("advanced-low", "Advanced-Low")]

suite : Test
suite =
    describe "questions" [
      describe "answers" [
        test "radio buttons can be selected mutually exclusively (same name attributes)" <|
          \() -> test_answer_field_mutual_exclusion
      ]
    ]
