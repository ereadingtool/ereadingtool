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

intersperseWordsWith : String -> (String, Int) -> List (String, Int) -> List (String, Int)
intersperseWordsWith str ((token, token_occurrence) as token_instance) tokens =
  case has_punctuation token of
    True ->
      tokens ++ [token_instance]

    False ->
      tokens ++ [(str, 0), token_instance]

intersperseWithWhitespace : List (String, Int) -> List (String, Int)
intersperseWithWhitespace word_tokens =
  List.foldl (intersperseWordsWith " ") [] word_tokens

countOccurrence : String -> (List (String, Int), Dict String Int) -> (List (String, Int), Dict String Int)
countOccurrence token (tokens, occurrences) =
  let
    normalized_token = String.toLower token
    num_of_prev_occurrences = Maybe.withDefault -1 (Dict.get normalized_token occurrences)
    instance = num_of_prev_occurrences + 1
    new_occurrences = Dict.insert normalized_token instance occurrences
    new_tokens = tokens ++ [(token, instance)]
  in
    (new_tokens, new_occurrences)

countOccurrences : List String -> Dict String Int -> (List (String, Int), Dict String Int)
countOccurrences words occurrences =
  List.foldl countOccurrence ([], occurrences) words

parseCompoundWord :
     (Int -> String -> Maybe (Int, Int, Int))
  -> (String, Int)
  -> (List (String, Int), (Int, List String))
  -> (List (String, Int), (Int, List String))
parseCompoundWord is_part_of_compound_word (token, instance) (token_occurrences, (compound_index, compound_token)) =
  case is_part_of_compound_word instance token of
    Just (group_instance, pos, compound_word_length) ->
      case pos == compound_index of
        True ->
          if pos+1 == compound_word_length then
            let
              compound_word = String.join " " (compound_token ++ [token])
              compound_word_instance = (compound_word, group_instance)
            in
              -- we're at the end of a compound word
              (token_occurrences ++ [compound_word_instance], (0, []))
          else
            -- token is part of a compound word and is in the right position
              (token_occurrences, (pos+1, compound_token ++ [token]))

        False ->
          -- token is part of a compound word but not the right position
          (token_occurrences ++ [(token, instance)], (0, []))

    Nothing ->
      -- regular word
      (token_occurrences ++ [(token, instance)], (0, []))

parseCompoundWords : (Int -> String -> Maybe (Int, Int, Int)) -> List (String, Int) -> List (String, Int)
parseCompoundWords is_part_of_compound_word token_occurrences =
  let
    (token_occurrences_with_compound_words, _) =
      List.foldl (parseCompoundWord is_part_of_compound_word) ([], (0, [])) token_occurrences
  in
    token_occurrences_with_compound_words

tagWordAndToVDOM :
     (Int -> String -> Html msg)
  -> (Int -> String -> Maybe (Int, Int, Int))
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

        (counted_occurrences, token_occurrences) = countOccurrences word_tokens occurrences

        counted_words = intersperseWithWhitespace (parseCompoundWords is_part_of_compound_word counted_occurrences)

        _ = Debug.log "text words" counted_words

        new_node = span [] (List.map (\(token, instance) -> tag_word instance token) counted_words)
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
  -> (Int -> String -> Maybe (Int, Int, Int))
  -> Dict String Int
  -> List HtmlParser.Node
  -> (List (Html msg), Dict String Int)
tagWordsToVDOMWithFreqs tag_word is_part_of_compound_word occurrences nodes =
  List.foldl (tagWordAndToVDOM tag_word is_part_of_compound_word) ([], occurrences) nodes

tagWordsAndToVDOM :
     (Int -> String -> Html msg)
  -> (Int -> String -> Maybe (Int, Int, Int))
  -> List HtmlParser.Node
  -> List (Html msg)
tagWordsAndToVDOM tag_word is_part_of_compound_word nodes =
    Tuple.first
 <| tagWordsToVDOMWithFreqs tag_word is_part_of_compound_word Dict.empty nodes