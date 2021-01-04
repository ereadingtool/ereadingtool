module Text.Section.Words.Tag exposing (Word(..), WordRecord, parse, toTaggedHtml)

import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes
import Html.Parser
import Html.Parser.Util
import Parser exposing (..)
import Regex
import Text.Section.Component exposing (index)
import Text.Translations exposing (TextGroupDetails)
import Text.Translations.Model exposing (inCompoundWord)


type Word
    = ValidWord String
    | InvalidWord String
    | CompoundWord String Int


type alias WordRecord =
    { leadingPunctuation : String
    , word : Word
    , trailingPunctuation : String
    }



-- TAG


toTaggedHtml :
    { tagWord : Int -> { leadingPunctuation : String, token : String, trailingPunctuation : String } -> Html msg
    , inCompoundWord : Int -> String -> Maybe TextGroupDetails
    , nodes : List Html.Parser.Node
    }
    -> List (Html msg)
toTaggedHtml { tagWord, inCompoundWord, nodes } =
    Tuple.first <|
        nodesToTaggedHtml
            { tagWord = tagWord
            , inCompoundWord = inCompoundWord
            , occurrences = Dict.empty
            , nodes = nodes
            }


nodesToTaggedHtml :
    { tagWord : Int -> { leadingPunctuation : String, token : String, trailingPunctuation : String } -> Html msg
    , inCompoundWord : Int -> String -> Maybe TextGroupDetails
    , occurrences : Dict String Int
    , nodes : List Html.Parser.Node
    }
    -> ( List (Html msg), Dict String Int )
nodesToTaggedHtml { tagWord, inCompoundWord, occurrences, nodes } =
    List.foldl (nodeToTaggedHtml tagWord inCompoundWord) ( [], occurrences ) nodes
        |> (\( nds, occrs ) -> ( List.intersperse (Html.text " ") nds, occrs ))


nodeToTaggedHtml :
    (Int -> { leadingPunctuation : String, token : String, trailingPunctuation : String } -> Html msg)
    -> (Int -> String -> Maybe TextGroupDetails)
    -> Html.Parser.Node
    -> ( List (Html msg), Dict String Int )
    -> ( List (Html msg), Dict String Int )
nodeToTaggedHtml tagWord inCompoundWord parsedNode ( html, occurrences ) =
    case parsedNode of
        Html.Parser.Text str ->
            let
                {- Parse each word in the text, breaking it apart into leading punctuation, the word,
                   and trailing punctuation.
                -}
                wordRecords =
                    List.map
                        (\word ->
                            case run parse word of
                                Ok wordRecord ->
                                    wordRecord

                                Err err ->
                                    { leadingPunctuation = ""
                                    , word = InvalidWord word
                                    , trailingPunctuation = ""
                                    }
                        )
                        (String.words str)

                {- Index single words. The indices are used to reference the correct translation
                   for each word. Occurrences are used internally to determine indices by tracking previous
                   occurrences of a word, but we throw them away because we create the final occurences when
                   we reindex.
                -}
                ( indexedWordRecords, _ ) =
                    List.foldl indexWord ( [], occurrences ) wordRecords

                {- Determine and apply compound words. Single words know which group they belong
                   to and we use that information to group them together by working through them
                   from the right.
                -}
                wordRecordsCompoundsApplied =
                    List.foldr (compoundWords inCompoundWord) [] indexedWordRecords

                {- Reindex the words. The compound words need to be indexed and the occurrences
                   for single words need to be updated, because some of them have been merged into
                   a compound word. The instance for single words should not change because we use
                   that to look up translations, but the the occurence should change to tag the words
                   in their correct position.
                -}
                ( reindexedWordRecords, updatedOccurrences ) =
                    List.foldl reindexWord ( [], occurrences ) wordRecordsCompoundsApplied

                {- Generate an Html node for each word, including the word and a tag if it is
                   a valid word or a compound word.
                -}
                nodes =
                    List.map
                        (\( wordRecord, instance ) ->
                            case wordRecord.word of
                                ValidWord word ->
                                    tagWord instance
                                        { leadingPunctuation = wordRecord.leadingPunctuation
                                        , token = word
                                        , trailingPunctuation = wordRecord.trailingPunctuation
                                        }

                                InvalidWord word ->
                                    Html.text
                                        (wordRecord.leadingPunctuation
                                            ++ word
                                            ++ wordRecord.trailingPunctuation
                                        )

                                CompoundWord word groupInstance ->
                                    tagWord instance
                                        { leadingPunctuation = wordRecord.leadingPunctuation
                                        , token = word
                                        , trailingPunctuation = wordRecord.trailingPunctuation
                                        }
                        )
                        reindexedWordRecords

                {- Intersperse whitespace into the nodes to reconstruct the original whitespace in
                   the text.
                -}
                nodesWithWhitespace =
                    List.intersperse (Html.text " ") nodes

                --
            in
            ( html ++ nodesWithWhitespace, updatedOccurrences )

        Html.Parser.Element name attributes nodes ->
            let
                ( childNodes, updatedOccurrences ) =
                    nodesToTaggedHtml
                        { tagWord = tagWord
                        , inCompoundWord = inCompoundWord
                        , occurrences = occurrences
                        , nodes = nodes
                        }

                node =
                    Html.node
                        name
                        (List.map
                            (\( attrName, val ) ->
                                Html.Attributes.attribute attrName val
                            )
                            attributes
                        )
                        childNodes
            in
            ( html ++ [ node ], updatedOccurrences )

        Html.Parser.Comment _ ->
            ( html, occurrences )


indexWord :
    WordRecord
    -> ( List ( WordRecord, Int ), Dict String Int )
    -> ( List ( WordRecord, Int ), Dict String Int )
indexWord wordRecord ( wordRecords, occurrences ) =
    case wordRecord.word of
        ValidWord token ->
            let
                normalizedToken =
                    String.toLower token

                previousOccurrences =
                    Maybe.withDefault -1 (Dict.get normalizedToken occurrences)

                instance =
                    previousOccurrences + 1
            in
            ( wordRecords ++ [ ( wordRecord, instance ) ], Dict.insert normalizedToken instance occurrences )

        InvalidWord token ->
            -- no need to track invalid words, we won't tag them
            ( wordRecords ++ [ ( wordRecord, 0 ) ], occurrences )

        CompoundWord _ _ ->
            -- we should not have any compound words during the first round of indexing
            ( wordRecords, occurrences )


{-| Words are compounded by crawling from right to left over a list of word
records. Valid and and already existing compound words might become part of
a new compound word.

We check the group ID of each valid or compound word and create new compound
words when they match.

-}
compoundWords :
    (Int -> String -> Maybe TextGroupDetails)
    -> ( WordRecord, Int )
    -> List ( WordRecord, Int )
    -> List ( WordRecord, Int )
compoundWords inCompoundWord ( leftWordRecord, leftIndex ) accWordRecords =
    case accWordRecords of
        ( rightWordRecord, rightIndex ) :: records ->
            case leftWordRecord.word of
                ValidWord leftWord ->
                    case inCompoundWord leftIndex leftWord of
                        Just leftGroup ->
                            case rightWordRecord.word of
                                ValidWord rightWord ->
                                    case inCompoundWord rightIndex rightWord of
                                        Just rightGroup ->
                                            if leftGroup.id == rightGroup.id then
                                                compoundWord
                                                    { leftWordRecord = leftWordRecord
                                                    , leftWord = leftWord
                                                    , rightWordRecord = rightWordRecord
                                                    , rightWord = rightWord
                                                    , groupId = rightGroup.id
                                                    }
                                                    :: records

                                            else
                                                ( leftWordRecord, leftIndex ) :: accWordRecords

                                        Nothing ->
                                            ( leftWordRecord, leftIndex ) :: accWordRecords

                                CompoundWord rightWord groupInstance ->
                                    if leftGroup.id == groupInstance then
                                        compoundWord
                                            { leftWordRecord = leftWordRecord
                                            , leftWord = leftWord
                                            , rightWordRecord = rightWordRecord
                                            , rightWord = rightWord
                                            , groupId = groupInstance
                                            }
                                            :: records

                                    else
                                        ( leftWordRecord, leftIndex ) :: accWordRecords

                                InvalidWord _ ->
                                    ( leftWordRecord, leftIndex ) :: accWordRecords

                        Nothing ->
                            ( leftWordRecord, leftIndex ) :: accWordRecords

                _ ->
                    ( leftWordRecord, leftIndex ) :: accWordRecords

        [] ->
            [ ( leftWordRecord, leftIndex ) ]


{-| A compound word is made of a left word and a right word. We preserve the
punctuation between the words because phrases might be merged over punctuation.
The instance of the compound word is assigned as 0 at while compounding because
we cannot know the index until all of the compounds have been assembled.
-}
compoundWord :
    { leftWordRecord : WordRecord
    , leftWord : String
    , rightWordRecord : WordRecord
    , rightWord : String
    , groupId : Int
    }
    -> ( WordRecord, Int )
compoundWord { leftWordRecord, leftWord, rightWordRecord, rightWord, groupId } =
    ( { leadingPunctuation = leftWordRecord.leadingPunctuation
      , word =
            CompoundWord
                (leftWord
                    ++ leftWordRecord.trailingPunctuation
                    ++ " "
                    ++ rightWordRecord.leadingPunctuation
                    ++ rightWord
                )
                groupId
      , trailingPunctuation = rightWordRecord.trailingPunctuation
      }
    , 0
    )


reindexWord :
    ( WordRecord, Int )
    -> ( List ( WordRecord, Int ), Dict String Int )
    -> ( List ( WordRecord, Int ), Dict String Int )
reindexWord ( wordRecord, inst ) ( wordRecords, occurrences ) =
    case wordRecord.word of
        ValidWord token ->
            let
                normalizedToken =
                    String.toLower token

                previousOccurrences =
                    Maybe.withDefault -1 (Dict.get normalizedToken occurrences)

                occurence =
                    previousOccurrences + 1
            in
            -- preserve the instance, but update the occurence
            ( wordRecords ++ [ ( wordRecord, inst ) ], Dict.insert normalizedToken occurence occurrences )

        InvalidWord token ->
            -- no need to track invalid words, we won't tag them
            ( wordRecords ++ [ ( wordRecord, 0 ) ], occurrences )

        CompoundWord token _ ->
            let
                normalizedToken =
                    String.toLower token

                previousOccurrences =
                    Maybe.withDefault -1 (Dict.get normalizedToken occurrences)

                instance =
                    previousOccurrences + 1
            in
            ( wordRecords ++ [ ( wordRecord, instance ) ], Dict.insert normalizedToken instance occurrences )



-- PARSE


parse : Parser WordRecord
parse =
    succeed WordRecord
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
        problem "Could not parse a valid word."


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
    List.any (\c -> c == char) (cyrillicChars ++ [ '-', '/' ])


cyrillicChars : List Char
cyrillicChars =
    String.toList "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя"
