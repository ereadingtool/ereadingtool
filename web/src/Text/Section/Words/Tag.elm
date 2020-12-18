module Text.Section.Words.Tag exposing (ParsedWord, Word(..), parse, tagWordsAndToVDOM)

import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes
import Html.Parser
import Html.Parser.Util
import Parser exposing (..)
import Regex
import Text.Section.Component exposing (index)
import Text.Translations.Model exposing (isPartOfCompoundWord)


tagWordsAndToVDOM :
    -- (Int -> String -> Html msg)
    (Int -> { leadingPunctuation : String, token : String, trailingPunctuation : String } -> Html msg)
    -> (Int -> String -> Maybe ( Int, Int, Int ))
    -> List Html.Parser.Node
    -> List (Html msg)
tagWordsAndToVDOM tag_word is_part_of_compound_word nodes =
    Tuple.first <|
        tagWordsToVDOMWithFreqs tag_word is_part_of_compound_word Dict.empty nodes


tagWordsToVDOMWithFreqs :
    (Int -> { leadingPunctuation : String, token : String, trailingPunctuation : String } -> Html msg)
    -> (Int -> String -> Maybe ( Int, Int, Int ))
    -> Dict String Int
    -> List Html.Parser.Node
    -> ( List (Html msg), Dict String Int )
tagWordsToVDOMWithFreqs tag_word is_part_of_compound_word occurrences nodes =
    List.foldl (tagWordAndToVDOM tag_word is_part_of_compound_word) ( [], occurrences ) nodes
        |> (\( ns, occs ) -> ( List.intersperse (Html.text " ") ns, occs ))


tagWordAndToVDOM :
    (Int -> { leadingPunctuation : String, token : String, trailingPunctuation : String } -> Html msg)
    -> (Int -> String -> Maybe ( Int, Int, Int ))
    -> Html.Parser.Node
    -> ( List (Html msg), Dict String Int )
    -> ( List (Html msg), Dict String Int )
tagWordAndToVDOM tag_word inCompoundWord node ( html, occurrences ) =
    case node of
        Html.Parser.Text str ->
            let
                wordRecords =
                    List.map
                        (\word ->
                            case run parse word of
                                Ok wordRecord ->
                                    wordRecord

                                Err err ->
                                    { leadingPunctuation = ""
                                    , word = InvalidWord ""
                                    , trailingPunctuation = ""
                                    }
                        )
                        (String.words str)

                ( indexedWordRecords, occurences ) =
                    List.foldl indexWord ( [], occurrences ) wordRecords

                wordRecordsCompoundsApplied =
                    List.foldr (compoundWords inCompoundWord) [] indexedWordRecords

                ( reindexedWordRecords, updatedOccurences ) =
                    List.foldl indexWord ( [], occurrences ) (List.map Tuple.first wordRecordsCompoundsApplied)

                nodes =
                    List.map
                        (\( wordRecord, instance ) ->
                            case wordRecord.word of
                                ValidWord word ->
                                    tag_word instance
                                        { leadingPunctuation = wordRecord.leadingPunctuation
                                        , token = word
                                        , trailingPunctuation = wordRecord.trailingPunctuation
                                        }

                                InvalidWord word ->
                                    Html.text word

                                CompoundWord compoundWord groupInstance ->
                                    tag_word instance
                                        { leadingPunctuation = wordRecord.leadingPunctuation
                                        , token = compoundWord
                                        , trailingPunctuation = wordRecord.trailingPunctuation
                                        }
                        )
                        reindexedWordRecords

                nodesWithWhitespace =
                    List.intersperse (Html.text " ") nodes

                --
            in
            ( html ++ nodesWithWhitespace, updatedOccurences )

        Html.Parser.Element name attrs nodes ->
            let
                ( new_msgs, new_occurrences ) =
                    tagWordsToVDOMWithFreqs tag_word inCompoundWord occurrences nodes

                new_node =
                    Html.node
                        name
                        (List.map (\( nm, value ) -> Html.Attributes.attribute nm value) attrs)
                        new_msgs
            in
            ( html ++ [ new_node ], new_occurrences )

        (Html.Parser.Comment str) as comment ->
            ( html ++ [ Html.text "" ], occurrences )



-- OLD


indexWord : ParsedWord -> ( List ( ParsedWord, Int ), Dict String Int ) -> ( List ( ParsedWord, Int ), Dict String Int )
indexWord wordRecord ( wordRecords, occurrences ) =
    case wordRecord.word of
        ValidWord token ->
            let
                normalized_token =
                    String.toLower token

                num_of_prev_occurrences =
                    Maybe.withDefault -1 (Dict.get normalized_token occurrences)

                instance =
                    num_of_prev_occurrences + 1

                new_occurrences =
                    Dict.insert normalized_token instance occurrences

                new_tokens =
                    wordRecords ++ [ ( wordRecord, instance ) ]
            in
            ( new_tokens, new_occurrences )

        InvalidWord _ ->
            ( wordRecords ++ [ ( wordRecord, 0 ) ], occurrences )

        CompoundWord token _ ->
            let
                normalized_token =
                    String.toLower token

                num_of_prev_occurrences =
                    Maybe.withDefault -1 (Dict.get normalized_token occurrences)

                instance =
                    num_of_prev_occurrences + 1

                new_occurrences =
                    Dict.insert normalized_token instance occurrences

                new_tokens =
                    wordRecords ++ [ ( wordRecord, instance ) ]
            in
            ( new_tokens, new_occurrences )


compoundWords :
    (Int -> String -> Maybe ( Int, Int, Int ))
    -> ( ParsedWord, Int )
    -> List ( ParsedWord, Int )
    -> List ( ParsedWord, Int )
compoundWords inCompoundWord ( leftWordRecord, leftIndex ) accWordRecords =
    case accWordRecords of
        ( rightWordRecord, rightIndex ) :: records ->
            case leftWordRecord.word of
                ValidWord leftWord ->
                    case inCompoundWord leftIndex leftWord of
                        Just ( leftGroupInstance, _, _ ) ->
                            case rightWordRecord.word of
                                ValidWord rightWord ->
                                    case inCompoundWord rightIndex rightWord of
                                        Just ( rightGroupInstance, _, _ ) ->
                                            if leftGroupInstance == rightGroupInstance then
                                                [ ( { leadingPunctuation = leftWordRecord.leadingPunctuation
                                                    , word =
                                                        CompoundWord
                                                            (leftWord
                                                                ++ leftWordRecord.trailingPunctuation
                                                                ++ " "
                                                                ++ rightWordRecord.leadingPunctuation
                                                                ++ rightWord
                                                            )
                                                            rightGroupInstance
                                                    , trailingPunctuation = rightWordRecord.trailingPunctuation
                                                    }
                                                  , leftIndex
                                                  )
                                                ]
                                                    ++ records

                                            else
                                                [ ( leftWordRecord, leftIndex ) ] ++ accWordRecords

                                        Nothing ->
                                            [ ( leftWordRecord, leftIndex ) ] ++ accWordRecords

                                CompoundWord rightWord groupInstance ->
                                    if leftGroupInstance == groupInstance then
                                        [ ( { leadingPunctuation = leftWordRecord.leadingPunctuation
                                            , word =
                                                CompoundWord
                                                    (leftWord
                                                        ++ leftWordRecord.trailingPunctuation
                                                        ++ " "
                                                        ++ rightWordRecord.leadingPunctuation
                                                        ++ rightWord
                                                    )
                                                    groupInstance
                                            , trailingPunctuation = rightWordRecord.trailingPunctuation
                                            }
                                          , leftIndex
                                          )
                                        ]
                                            ++ records

                                    else
                                        [ ( leftWordRecord, leftIndex ) ] ++ accWordRecords

                                InvalidWord _ ->
                                    [ ( leftWordRecord, leftIndex ) ] ++ accWordRecords

                        Nothing ->
                            [ ( leftWordRecord, leftIndex ) ] ++ accWordRecords

                _ ->
                    [ ( leftWordRecord, leftIndex ) ] ++ accWordRecords

        [] ->
            [ ( leftWordRecord, leftIndex ) ]



-- PARSE


type Word
    = ValidWord String
    | InvalidWord String
    | CompoundWord String Int


type alias ParsedWord =
    { leadingPunctuation : String
    , word : Word
    , trailingPunctuation : String
    }


parse : Parser ParsedWord
parse =
    succeed ParsedWord
        |= (getChompedString <| chompWhile isLeadingPunctuation)
        |= parseWord
        |= (getChompedString <| chompWhile isTrailingPunctuation)
        |. end


parseWord : Parser Word
parseWord =
    (getChompedString <| chompWhile isValidChar)
        |> andThen checkWord


checkWord : String -> Parser Word
checkWord validWord =
    if not (String.isEmpty validWord) then
        succeed (ValidWord validWord)

    else
        succeed InvalidWord
            |= (getChompedString <|
                    chompWhile (\c -> not (isTrailingPunctuation c))
               )


isLeadingPunctuation : Char -> Bool
isLeadingPunctuation char =
    (char == '«' || char == '"' || char == '„')
        || (char == '(' || char == '[' || char == '{' || char == '<')


isTrailingPunctuation : Char -> Bool
isTrailingPunctuation char =
    (char == ',' || char == '.' || char == '!' || char == '?')
        || (char == ':' || char == ';')
        || (char == '»' || char == '"' || char == '“')
        || (char == ')' || char == ']' || char == '}' || char == '>')
        || (char == '…')


isValidChar : Char -> Bool
isValidChar char =
    List.any (\c -> c == char) (cyrillicChars ++ [ '-' ])


cyrillicChars : List Char
cyrillicChars =
    String.toList "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя"



--------------------------
-- ORIGINAL IMPLEMENTATION
--------------------------


tagWordsToVDOMWithFreqs_old :
    (Int -> String -> Html msg)
    -> (Int -> String -> Maybe ( Int, Int, Int ))
    -> Dict String Int
    -> List Html.Parser.Node
    -> ( List (Html msg), Dict String Int )
tagWordsToVDOMWithFreqs_old tag_word is_part_of_compound_word occurrences nodes =
    List.foldl (tagWordAndToVDOM_old tag_word is_part_of_compound_word) ( [], occurrences ) nodes


tagWordAndToVDOM_old :
    (Int -> String -> Html msg)
    -> (Int -> String -> Maybe ( Int, Int, Int ))
    -> Html.Parser.Node
    -> ( List (Html msg), Dict String Int )
    -> ( List (Html msg), Dict String Int )
tagWordAndToVDOM_old tag_word is_part_of_compound_word node ( html, occurrences ) =
    case node of
        Html.Parser.Text str ->
            let
                word_tokens =
                    List.concat <|
                        List.map maybeParseWordWithPunctuation (String.words str)

                ( counted_occurrences, token_occurrences ) =
                    countOccurrences word_tokens occurrences

                counted_words =
                    intersperseWithWhitespace (parseCompoundWords is_part_of_compound_word counted_occurrences)

                new_nodes =
                    List.map (\( token, instance ) -> tag_word instance token) counted_words
            in
            ( html ++ new_nodes, token_occurrences )

        Html.Parser.Element name attrs nodes ->
            let
                ( new_msgs, new_occurrences ) =
                    tagWordsToVDOMWithFreqs_old tag_word is_part_of_compound_word occurrences nodes

                new_node =
                    Html.node
                        name
                        (List.map (\( nm, value ) -> Html.Attributes.attribute nm value) attrs)
                        new_msgs
            in
            ( html ++ [ new_node ], new_occurrences )

        (Html.Parser.Comment str) as comment ->
            ( html ++ [ Html.text "" ], occurrences )



-- COMPUND WORDS


parseCompoundWords : (Int -> String -> Maybe ( Int, Int, Int )) -> List ( String, Int ) -> List ( String, Int )
parseCompoundWords is_part_of_compound_word token_occurrences =
    let
        ( token_occurrences_with_compound_words, _ ) =
            List.foldl (parseCompoundWord is_part_of_compound_word) ( [], ( 0, [] ) ) token_occurrences
    in
    token_occurrences_with_compound_words


parseCompoundWord :
    (Int -> String -> Maybe ( Int, Int, Int ))
    -> ( String, Int )
    -> ( List ( String, Int ), ( Int, List String ) )
    -> ( List ( String, Int ), ( Int, List String ) )
parseCompoundWord is_part_of_compound_word ( token, instance ) ( token_occurrences, ( compound_index, compound_token ) ) =
    case is_part_of_compound_word instance token of
        Just ( group_instance, pos, compound_word_length ) ->
            if pos == compound_index then
                if pos + 1 == compound_word_length then
                    let
                        compound_word =
                            String.join " " (compound_token ++ [ token ])

                        compound_word_instance =
                            ( compound_word, group_instance )
                    in
                    -- we're at the end of a compound word
                    ( token_occurrences ++ [ compound_word_instance ], ( 0, [] ) )

                else
                    -- token is part of a compound word and is in the right position
                    ( token_occurrences, ( pos + 1, compound_token ++ [ token ] ) )

            else
                -- token is part of a compound word but not in the right position
                ( token_occurrences ++ [ ( token, instance ) ], ( 0, [] ) )

        Nothing ->
            -- regular word
            ( token_occurrences ++ [ ( token, instance ) ], ( 0, [] ) )


countOccurrences : List String -> Dict String Int -> ( List ( String, Int ), Dict String Int )
countOccurrences words occurrences =
    List.foldl countOccurrence ( [], occurrences ) words


countOccurrence : String -> ( List ( String, Int ), Dict String Int ) -> ( List ( String, Int ), Dict String Int )
countOccurrence token ( tokens, occurrences ) =
    let
        normalized_token =
            String.toLower token

        num_of_prev_occurrences =
            Maybe.withDefault -1 (Dict.get normalized_token occurrences)

        instance =
            num_of_prev_occurrences + 1

        new_occurrences =
            Dict.insert normalized_token instance occurrences

        new_tokens =
            tokens ++ [ ( token, instance ) ]
    in
    ( new_tokens, new_occurrences )


intersperseWithWhitespace : List ( String, Int ) -> List ( String, Int )
intersperseWithWhitespace word_tokens =
    List.foldl (intersperseWordsWith " ") [] word_tokens


intersperseWordsWith : String -> ( String, Int ) -> List ( String, Int ) -> List ( String, Int )
intersperseWordsWith str (( token, token_occurrence ) as token_instance) tokens =
    if hasPunctuation token then
        tokens ++ [ token_instance ]

    else
        tokens ++ [ ( str, 0 ), token_instance ]



-- WORD


maybeParseWordWithPunctuation : String -> List String
maybeParseWordWithPunctuation str =
    let
        matches =
            -- Regex.find (Regex.AtMost 1) punctuation_re str
            Regex.findAtMost 1 punctuation_re str

        end_of_str_index =
            String.length str
    in
    case matches of
        match :: [] ->
            let
                end_of_match_index =
                    match.index + 1

                punctuation_char =
                    String.slice match.index end_of_match_index str

                word =
                    String.slice 0 match.index str

                rest_of_str =
                    String.slice end_of_match_index end_of_str_index str
            in
            [ word, String.join "" [ punctuation_char, rest_of_str ] ]

        _ ->
            [ str ]


hasPunctuation : String -> Bool
hasPunctuation =
    Regex.contains punctuation_re


punctuation_re : Regex.Regex
punctuation_re =
    -- Regex.regex "[?!.,»«—\\-();]"
    Maybe.withDefault Regex.never <|
        Regex.fromString "[?!.,»«—\\-();]"
