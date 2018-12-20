module Text.Section.Words.Tag exposing (tagWordsAndToVDOM)

import Regex
import Dict exposing (Dict)

import HtmlParser

import Html.Attributes

import VirtualDom

import Html exposing (Html, div, span)


punctuation_re : Regex.Regex
punctuation_re =
  Regex.regex "[?!.,]"

has_punctuation : String -> Bool
has_punctuation =
  Regex.contains punctuation_re

maybeParseWordWithPunctuation : String -> List String
maybeParseWordWithPunctuation str =
  let
    matches = Regex.find (Regex.AtMost 1) punctuation_re str
  in
    case matches of
      match :: [] ->
        let
          punctuation_char = String.slice match.index (match.index + 1) str
          word = String.slice 0 match.index str
        in
          [word, punctuation_char]

      _ ->
        [str]

intersperseWords : String -> List String -> List String
intersperseWords token tokens =
  let
    whitespace = " "
  in
    case has_punctuation token of
      True ->
        tokens ++ [token]

      False ->
        tokens ++ [whitespace, token]

countOccurrences : String -> (List (String, Int), Dict String Int) -> (List (String, Int), Dict String Int)
countOccurrences token (tokens, occurrences) =
  let
    num_of_prev_occurrences = Maybe.withDefault -1 (Dict.get token occurrences)
    instance = num_of_prev_occurrences + 1
    new_occurrences = Dict.insert token instance occurrences
    new_tokens = tokens ++ [(token, instance)]
  in
    (new_tokens, new_occurrences)

tagWordAndToVDOM : (Int -> String -> Html msg) -> HtmlParser.Node -> Html msg
tagWordAndToVDOM tag_word node =
  case node of
    HtmlParser.Text str ->
      let
        word_tokens =
             List.concat
          <| List.map maybeParseWordWithPunctuation (String.words str)

        tokenized_text = List.foldl intersperseWords [] word_tokens

        (items, _) = List.foldl countOccurrences ([], Dict.empty) tokenized_text
      in
        span [] (List.map (\(token, instance) -> tag_word instance token) items)

    HtmlParser.Element name attrs nodes ->
      Html.node
        name
        (List.map (\(name, value) ->
          Html.Attributes.attribute name value) attrs
        )
        (tagWordsAndToVDOM tag_word nodes)

    (HtmlParser.Comment str) as comment ->
        VirtualDom.text ""

tagWordsAndToVDOM : (Int -> String -> Html msg) -> List HtmlParser.Node -> List (Html msg)
tagWordsAndToVDOM tag_word nodes =
  List.map (tagWordAndToVDOM tag_word) nodes