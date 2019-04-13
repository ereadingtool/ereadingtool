module Test.Text.Parse exposing (..)

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

tagWord :
     (Int -> String -> HtmlParser.Node)
  -> (Int -> String -> Maybe (Int, Int, Int))
  -> HtmlParser.Node
  -> (List (HtmlParser.Node), Dict String Int)
  -> (List (HtmlParser.Node), Dict String Int)
tagWord tag_word is_part_of_compound_word node (nodes, occurrences) =
  case node of
    HtmlParser.Text str ->
      let
        word_tokens =
             List.concat
          <| List.map Text.Section.Words.Tag.maybeParseWordWithPunctuation (String.words str)

        (counted_occurrences, token_occurrences) = Text.Section.Words.Tag.countOccurrences word_tokens occurrences

        counted_words =
          Text.Section.Words.Tag.intersperseWithWhitespace
            (Text.Section.Words.Tag.parseCompoundWords is_part_of_compound_word counted_occurrences)

        new_node =
          HtmlParser.Element "span" [] (List.map (\(token, instance) -> tag_word instance token) counted_words)
      in
        (nodes ++ [new_node], token_occurrences)

    HtmlParser.Element name attrs nodes ->
      let
        (child_nodes, new_occurrences) = tagWordsWithFreqs tag_word is_part_of_compound_word occurrences nodes

        new_node = HtmlParser.Element name attrs child_nodes
      in
        (nodes ++ [new_node], new_occurrences)

    (HtmlParser.Comment str) as comment ->
      (nodes ++ [comment], occurrences)

tagWordsWithFreqs :
     (Int -> String -> HtmlParser.Node)
  -> (Int -> String -> Maybe (Int, Int, Int))
  -> Dict String Int
  -> List HtmlParser.Node
  -> (List (HtmlParser.Node), Dict String Int)
tagWordsWithFreqs tag_word is_part_of_compound_word occurrences nodes =
  List.foldl (tagWord tag_word is_part_of_compound_word) ([], occurrences) nodes

tagWordsToNodes :
     (Int -> String -> HtmlParser.Node)
  -> (Int -> String -> Maybe (Int, Int, Int))
  -> List HtmlParser.Node
  -> List (HtmlParser.Node)
tagWordsToNodes tag_word is_part_of_compound_word nodes =
    Tuple.first
 <| tagWordsWithFreqs tag_word is_part_of_compound_word Dict.empty nodes

test_text_section_body : String
test_text_section_body =
  """
<p>If you are reading a text and you come across an unfamiliar word, you can click on the word to receive a glossed
definition. Try clicking on some of the words from the excerpt from
Tolstoy&#39;s&nbsp;
<em>Childhood&nbsp;</em>below:</p>\n\n<p>&quot;Пить&nbsp;чай&nbsp;в&nbsp;лесу&nbsp;на&nbsp;траве&nbsp;---&nbsp;
считалось&nbsp;большим&nbsp;наслаждением.&quot;</p>\n\n<p>As you click the words, you will see the English equivalent
and the part of speech pop up in a little box near the word. In that box, you will also see the option to add that
word to your flashcards. Adding words to your flashcards will allow you to later review words that you learned in
current text.&nbsp;</p>
  """

tagWordToNode : Int -> String -> HtmlParser.Node
tagWordToNode instance token =
  let
    id = String.join "_" [toString instance, token]
  in
    case token == " " of
      True ->
        HtmlParser.Element "span" [("class", "space")] []

      False ->
        HtmlParser.Element "span" [
            ("id", id)
          , ("class", "defined_word")
          , ("class", "cursor")
        ] [
          HtmlParser.Element "span" [] [
            HtmlParser.Text token
          ]
        ]

is_part_of_compound_word : Int -> String -> Maybe (Int, Int, Int)
is_part_of_compound_word instance word =
  Nothing

test_parse_text_body :
  String -> (Int -> String -> HtmlParser.Node) -> (Int -> String -> Maybe (Int, Int, Int)) -> Expectation
test_parse_text_body body tag_word is_compound_word =
  let
    text_body_nodes =
      tagWordsToNodes tag_word is_part_of_compound_word (HtmlParser.parse body)
    _ = Debug.log "parsed HtmlParser.Nodes: " (text_body_nodes)
    _ = Debug.log "tolstoy" (HtmlParser.Util.getElementById "0_Tolstoy" text_body_nodes)
  in
    Expect.pass

suite : Test
suite =
  describe "text section body parse" [
    test "parse text body" <| \() -> test_parse_text_body test_text_section_body tagWordToNode is_part_of_compound_word
  ]
