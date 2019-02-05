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
    normalized_token = String.toLower token
    num_of_prev_occurrences = Maybe.withDefault -1 (Dict.get normalized_token occurrences)
    instance = num_of_prev_occurrences + 1
    new_occurrences = Dict.insert normalized_token instance occurrences
    new_tokens = tokens ++ [(token, instance)]
  in
    (new_tokens, new_occurrences)

parseCompoundWord :
     (String -> Maybe (Int, Int))
  -> String
  -> (List String, (Int, List String))
  -> (List String, (Int, List String))
parseCompoundWord is_part_of_compound_word token (tokens, (compound_index, compound_token)) =
  case is_part_of_compound_word token of
    Just (pos, length) ->
      case pos == compound_index of
        True ->
          if pos+1 == length then
            let
              compound_word = compound_token ++ [token]
            in
              -- we're at the end of a compound word
              (tokens ++ compound_word, (0, []))
          else
            -- token is part of a compound word and is in the right position
            (tokens, (pos+1, compound_token ++ [token]))

        False ->
          -- token is part of a compound word but not the right position
          (tokens, (0, []))

    Nothing ->
      -- regular word
      (tokens ++ [token], (0, []))

parseCompoundWords : (String -> Maybe (Int, Int)) -> List String -> List String
parseCompoundWords is_part_of_compound_word tokens =
  let
    (tokens_with_compound_words, _) = List.foldl (parseCompoundWord is_part_of_compound_word) ([], (0, [])) tokens
  in
    tokens_with_compound_words

tagWordAndToVDOM :
     (Int -> String -> Html msg)
  -> (String -> Maybe (Int, Int))
  -> HtmlParser.Node
  -> (List (Html msg), Dict String Int)
  -> (List (Html msg), Dict String Int)
tagWordAndToVDOM tag_word is_part_of_compound_word node (html, occurrences) =
  case node of
    HtmlParser.Text str ->
      let
        word_tokens =
             List.concat
          <| List.map maybeParseWordWithPunctuation (String.words str)

        tokenized_text = parseCompoundWords is_part_of_compound_word (List.foldl intersperseWords [] word_tokens)

        (counted_tokens, token_occurrences) = List.foldl countOccurrences ([], occurrences) tokenized_text

        new_node = span [] (List.map (\(token, instance) -> tag_word instance token) counted_tokens)
      in
        (html ++ [new_node], token_occurrences)

    HtmlParser.Element name attrs nodes ->
      let
        (new_msgs, new_occurrences) = tagWordsToVDOMWithFreqs tag_word is_part_of_compound_word occurrences nodes

        new_node =
          Html.node
            name
            (List.map (\(name, value) -> Html.Attributes.attribute name value) attrs)
            new_msgs
      in
        (html ++ [new_node], new_occurrences)

    (HtmlParser.Comment str) as comment ->
        (html ++ [VirtualDom.text ""], occurrences)

tagWordsToVDOMWithFreqs :
     (Int -> String -> Html msg)
  -> (String -> Maybe (Int, Int))
  -> Dict String Int
  -> List HtmlParser.Node
  -> (List (Html msg), Dict String Int)
tagWordsToVDOMWithFreqs tag_word is_part_of_compound_word occurrences nodes =
  List.foldl (tagWordAndToVDOM tag_word is_part_of_compound_word) ([], occurrences) nodes

tagWordsAndToVDOM :
     (Int -> String -> Html msg)
  -> (String -> Maybe (Int, Int))
  -> List HtmlParser.Node
  -> List (Html msg)
tagWordsAndToVDOM tag_word is_part_of_compound_word nodes =
    Tuple.first
 <| tagWordsToVDOMWithFreqs tag_word is_part_of_compound_word Dict.empty nodes