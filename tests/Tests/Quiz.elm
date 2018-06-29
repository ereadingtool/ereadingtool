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

import Text.View
import Text.Model exposing (TextDifficulty)
import Text.Component.Group

type Msg = TextMsg

test_quiz_component : Quiz.Component.QuizComponent
test_quiz_component =
  Quiz.Component.emptyQuizComponent

test_text_component_group : Text.Component.Group.TextComponentGroup
test_text_component_group =
  Quiz.Component.text_components test_quiz_component

text_difficulties : List TextDifficulty
text_difficulties = [("intermediate-mid", "Intermediate Mid"), ("advanced-low", "Advanced-Low")]

suite : Test
suite =
    describe "questions" [
      describe "answers" [
        test "radio buttons can be selected mutually exclusively (same name attributes)" <|
          \() ->
               Text.View.view_text_components (\_ -> TextMsg) test_text_component_group text_difficulties
            |> Query.fromHtml
            |> Query.findAll [
              attribute <| Attr.name "text_0_question_0_correct_answer"
            , tag "input"
            , attribute <| Attr.type_ "radio" ]
            |> Query.count (Expect.equal 4)

      ]
    ]
