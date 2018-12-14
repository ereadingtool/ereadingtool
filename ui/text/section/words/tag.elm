module Text.Section.Words.Tag exposing (tagWordsAndToVDOM)

import Regex

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

tagWordAndToVDOM : (Int -> Int -> String -> Html msg) -> Int -> HtmlParser.Node -> Html msg
tagWordAndToVDOM tag_word i node =
  case node of
    HtmlParser.Text str ->
      let
        words =
             List.foldl intersperseWords []
          <| List.concat
          <| List.map maybeParseWordWithPunctuation (String.words str)
      in
        span [] (List.indexedMap (tag_word i) words)

    HtmlParser.Element name attrs nodes ->
      Html.node
        name
        (List.map (\(name, value) ->
          Html.Attributes.attribute name value) attrs
        )
        (tagWordsAndToVDOM tag_word nodes)

    (HtmlParser.Comment str) as comment ->
        VirtualDom.text ""

tagWordsAndToVDOM : (Int -> Int -> String -> Html msg) -> List HtmlParser.Node -> List (Html msg)
tagWordsAndToVDOM tag_word nodes =
  List.indexedMap (tagWordAndToVDOM tag_word) nodes