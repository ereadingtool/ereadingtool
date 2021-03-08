module Test.Text.Words.Merge exposing (suite)

import Test exposing (Test, describe, test)

import Test.Text.Words.Merge.Example1 as Example1
import Test.Text.Words.Merge.Example2 as Example2

suite : Test
suite =
    describe "text words merge"
        [ test "test merge example 1"
          <| \() -> Example1.testMerge Example1.test_model 0 "something" 0 Example1.new_text_words
        , test "test merge example 2"
          <| \() -> Example2.testMerge Example2.test_model 0 "something" 0 Example2.new_text_words
        ]
