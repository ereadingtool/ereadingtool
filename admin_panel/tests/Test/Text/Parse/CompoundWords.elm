module Test.Text.Parse.CompoundWords exposing (..)


import Dict exposing (Dict)

import Text.Section.Words.Tag

import Expect exposing (Expectation)

import Html exposing (..)
import Html.Attributes exposing (class, classList)

import Text.Section.Words.Tag

import VirtualDom
import HtmlParser
import HtmlParser.Util

import Test exposing (Test, test, describe)


isPartOfCompoundWord : Int -> String -> Maybe (Int, Int, Int)
isPartOfCompoundWord instance word =
  case (instance, word) of
    (0, "Большой") ->
      Just (0, 0, 2)

    (0, "провал") ->
      Just (0, 1, 2)

    _ ->
      Nothing

testParseCompoundWords : (Int -> String -> Maybe (Int, Int, Int)) -> List (String, Int) -> Expectation
testParseCompoundWords is_compound_word count_occurrences =
  let
    new_count_occurrences = Text.Section.Words.Tag.parseCompoundWords is_compound_word count_occurrences

    _ = Debug.log "parsed compound words" new_count_occurrences
  in
    case List.head new_count_occurrences of
      Just first_instance ->
        Expect.equal first_instance ("Большой провал",0)

      Nothing ->
        Expect.fail "no compound word found!"

suite : Test
suite =
  describe "text section body parse" [
    test "test parse compound words" <| \() -> testParseCompoundWords isPartOfCompoundWord test_occurrences
  ]

test_occurrences : List (String, Int)
test_occurrences = [
   ("Большой",0)
  ,("провал",0)
  ,("грунта",0)
  ,("образовался",0)
  ,("на",0)
  ,("проезжей",0)
  ,("части",0)
  ,("Новоясеневского",0)
  ,("проспекта",0)
  ,("на",1)
  ,("юго",0)
  ,("-западе",0)
  ,("Москвы",0)
  ,(".",0)
  ,("Яма",0)
  ,("шириной",0)
  ,("в",0)
  ,("два",0)
  ,("и",0)
  ,("глубиной",0)
  ,("до",0)
  ,("шести",0)
  ,("метров",0)
  ,("мешает",0)
  ,("движению",0)
  ,("транспорта",0)
  ,(".",1)
  ,("Об",0)
  ,("этом",0)
  ,("в",1)
  ,("воскресенье",0)
  ,(",",0)
  ,("9",0)
  ,("апреля",0)
  ,(",",1)
  ,("сообщает",0)
  ,("РИА",0)
  ,("Новости",0)
  ,("со",0)
  ,("ссылкой",0)
  ,("на",2)
  ,("источник",0)
  ,("в",2)
  ,("экстренных",0)
  ,("службах",0)
  ,("столицы",0)
  ,(".",2) ]
