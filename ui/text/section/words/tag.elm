module Text.Section.Words.Tag exposing (tagWordsAndToVDOM)

import Regex

import HtmlParser
import HtmlParser.Util

import Html.Attributes

import VirtualDom

import Html exposing (Html, div, span)

import TextReader.Section.Model exposing (Section)



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

tagWordAndToVDOM : Section -> (Int -> Section -> Int -> String -> Html msg) -> Int -> HtmlParser.Node -> Html msg
tagWordAndToVDOM section tag_word i node =
  case node of
    HtmlParser.Text str ->
      let
        words =
             List.foldl intersperseWords []
          <| List.concat
          <| List.map maybeParseWordWithPunctuation (String.words str)
      in
        span [] (List.indexedMap (tag_word i section) words)

    HtmlParser.Element name attrs nodes ->
      Html.node
        name
        (List.map (\(name, value) ->
          Html.Attributes.attribute name value) attrs
        )
        (tagWordsAndToVDOM section tag_word)

    (HtmlParser.Comment str) as comment ->
        VirtualDom.text ""

tagWordsAndToVDOM : Section -> (Int -> Section -> Int -> String -> Html msg) -> List (Html msg)
tagWordsAndToVDOM section tag_word =
  let
    text_section = TextReader.Section.Model.textSection section
    nodes = HtmlParser.parse text_section.body
  in
    List.indexedMap (tagWordAndToVDOM section tag_word) nodes