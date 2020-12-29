module TagSection.Reader exposing (compoundWords, invalidWords, punctuation, singleWords)

import Array exposing (Array, empty)
import Dict exposing (Dict)
import Expect
import Fuzz exposing (Fuzzer, string)
import Html exposing (Html)
import Html.Attributes
import Html.Parser exposing (Node)
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (id, tag, text)
import Text.Section.Words.Tag exposing (toTaggedHtml)
import Text.Translations exposing (..)
import Text.Translations.Word.Kind exposing (WordKind(..))
import TextReader.Model
import TextReader.Section.Model exposing (Section, newSection, textSection)
import TextReader.TextWord exposing (TextWord)


singleWords : Test
singleWords =
    describe "Tags words in a section with no punctuation and no compound words"
        [ test "with no words" <|
            \_ ->
                let
                    section =
                        makeSection
                            ""
                            []
                in
                tagSection section
                    |> Query.fromHtml
                    |> Query.hasNot [ tag "span" ]
        , test "with one unglossed word" <|
            \_ ->
                let
                    section =
                        makeSection
                            "улыбка"
                            []
                in
                tagSection section
                    |> Query.fromHtml
                    |> Query.contains [ Html.text "улыбка" ]
        , test "with one glossed word" <|
            \_ ->
                let
                    section =
                        makeSection
                            "улыбка"
                            [ smile ]
                in
                tagSection section
                    |> Query.fromHtml
                    |> Query.children [ tag "span" ]
                    |> Query.first
                    |> Query.has [ tag "b", id "smile", text "улыбка" ]
        , test "with one unglossed word and one glossed word" <|
            \_ ->
                let
                    section =
                        makeSection
                            "солнечная улыбка"
                            [ smile ]
                in
                tagSection section
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ text "солнечная" ]
                        , Query.children [ tag "span" ]
                            >> Query.first
                            >> Query.has [ tag "b", id "smile", text "улыбка" ]
                        ]
        , test "with two glossed words" <|
            \_ ->
                let
                    section =
                        makeSection
                            "солнечная улыбка"
                            [ sunny, smile ]
                in
                tagSection section
                    |> Query.fromHtml
                    |> Query.children [ tag "span" ]
                    |> Expect.all
                        [ Query.index 0 >> Query.has [ tag "b", id "sunny", text "солнечная" ]
                        , Query.index 1 >> Query.has [ tag "b", id "smile", text "улыбка" ]
                        ]
        , test "with repeated word, different translations" <|
            \_ ->
                let
                    section =
                        makeSection
                            "улыбка улыбка"
                            [ grinAndSmile ]
                in
                tagSection section
                    |> Query.fromHtml
                    |> Query.children [ tag "span" ]
                    |> Expect.all
                        [ Query.index 0 >> Query.has [ tag "b", id "grin", text "улыбка" ]
                        , Query.index 1 >> Query.has [ tag "b", id "smile", text "улыбка" ]
                        ]
        ]


punctuation : Test
punctuation =
    describe "Tags words in a section with punctuation, but no compound words"
        [ describe "with leading punctuation"
            [ test "one unglossed word" <|
                \_ ->
                    let
                        section =
                            makeSection
                                "«улыбка"
                                []
                    in
                    tagSection section
                        |> Query.fromHtml
                        |> Query.contains [ Html.text "«улыбка" ]
            , test "one glossed word" <|
                \_ ->
                    let
                        section =
                            makeSection
                                "«улыбка"
                                [ smile ]
                    in
                    tagSection section
                        |> Query.fromHtml
                        |> Query.children [ tag "span" ]
                        |> Query.first
                        |> Expect.all
                            [ Query.has [ text "«" ]
                            , Query.has [ tag "b", id "smile", text "улыбка" ]
                            ]
            , test "one unglossed word and one glossed word" <|
                \_ ->
                    let
                        section =
                            makeSection
                                "«солнечная улыбка"
                                [ smile ]
                    in
                    tagSection section
                        |> Query.fromHtml
                        |> Expect.all
                            [ Query.has [ text "«солнечная" ]
                            , Query.children [ tag "span" ]
                                >> Query.first
                                >> Query.has [ tag "b", id "smile", text "улыбка" ]
                            ]
            , test "with two glossed words" <|
                \_ ->
                    let
                        section =
                            makeSection
                                "«солнечная улыбка"
                                [ sunny, smile ]
                    in
                    tagSection section
                        |> Query.fromHtml
                        |> Query.children [ tag "span" ]
                        |> Expect.all
                            [ Query.index 0
                                >> Expect.all
                                    [ Query.has [ text "«" ]
                                    , Query.has [ tag "b", id "sunny", text "солнечная" ]
                                    ]
                            , Query.index 1
                                >> Query.has [ tag "b", id "smile", text "улыбка" ]
                            ]
            ]
        , describe "with trailing punctuation"
            [ test "one unglossed word" <|
                \_ ->
                    let
                        section =
                            makeSection
                                "улыбка»"
                                []
                    in
                    tagSection section
                        |> Query.fromHtml
                        |> Query.contains [ Html.text "улыбка»" ]
            , test "one glossed word" <|
                \_ ->
                    let
                        section =
                            makeSection
                                "улыбка»"
                                [ smile ]
                    in
                    tagSection section
                        |> Query.fromHtml
                        |> Query.children [ tag "span" ]
                        |> Query.first
                        |> Expect.all
                            [ Query.has [ tag "b", id "smile", text "улыбка" ]
                            , Query.has [ text "»" ]
                            ]
            , test "one unglossed word and one glossed word" <|
                \_ ->
                    let
                        section =
                            makeSection
                                "солнечная улыбка»"
                                [ smile ]
                    in
                    tagSection section
                        |> Query.fromHtml
                        |> Expect.all
                            [ Query.has [ text "солнечная" ]
                            , Query.children [ tag "span" ]
                                >> Query.first
                                >> Expect.all
                                    [ Query.has [ tag "b", id "smile", text "улыбка" ]
                                    , Query.has [ text "»" ]
                                    ]
                            ]
            , test "with two glossed words" <|
                \_ ->
                    let
                        section =
                            makeSection
                                "солнечная улыбка»"
                                [ sunny, smile ]
                    in
                    tagSection section
                        |> Query.fromHtml
                        |> Query.children [ tag "span" ]
                        |> Expect.all
                            [ Query.index 0 >> Query.has [ tag "b", id "sunny", text "солнечная" ]
                            , Query.index 1
                                >> Expect.all
                                    [ Query.has [ tag "b", id "smile", text "улыбка" ]
                                    , Query.has [ text "»" ]
                                    ]
                            ]
            ]
        , describe "with enclosing punctuation"
            [ test "one unglossed word" <|
                \_ ->
                    let
                        section =
                            makeSection
                                "«улыбка»"
                                []
                    in
                    tagSection section
                        |> Query.fromHtml
                        |> Query.contains [ Html.text "«улыбка»" ]
            , test "one glossed word" <|
                \_ ->
                    let
                        section =
                            makeSection
                                "«улыбка»"
                                [ smile ]
                    in
                    tagSection section
                        |> Query.fromHtml
                        |> Query.children [ tag "span" ]
                        |> Query.first
                        |> Expect.all
                            [ Query.has [ text "«" ]
                            , Query.has [ tag "b", id "smile", text "улыбка" ]
                            , Query.has [ text "»" ]
                            ]
            , test "two unglossed word" <|
                \_ ->
                    let
                        section =
                            makeSection
                                "«солнечная улыбка»"
                                []
                    in
                    tagSection section
                        |> Query.fromHtml
                        |> Query.has
                            [ text "«солнечная"
                            , text "улыбка»"
                            ]
            , test "with two glossed words" <|
                \_ ->
                    let
                        section =
                            makeSection
                                "«солнечная улыбка»"
                                [ sunny, smile ]
                    in
                    tagSection section
                        |> Query.fromHtml
                        |> Query.children [ tag "span" ]
                        |> Expect.all
                            [ Query.index 0
                                >> Expect.all
                                    [ Query.has [ text "«" ]
                                    , Query.has [ tag "b", id "sunny", text "солнечная" ]
                                    ]
                            , Query.index 1
                                >> Expect.all
                                    [ Query.has [ tag "b", id "smile", text "улыбка" ]
                                    , Query.has [ text "»" ]
                                    ]
                            ]
            ]
        ]


compoundWords : Test
compoundWords =
    describe "Tags words in a section with compound words"
        [ test "with one glossed compound word (two word)" <|
            \_ ->
                let
                    section =
                        makeSection
                            "солнечная улыбка"
                            [ sunnyInCompound 30, smileInCompound 30, sunnySmile 30 ]
                in
                tagSection section
                    |> Query.fromHtml
                    |> Query.has [ tag "b", id "sunny smile", text "солнечная улыбка" ]
        , test "with one glossed compound word (three word)" <|
            \_ ->
                let
                    section =
                        makeSection
                            "твоя солнечная улыбка"
                            [ yourInCompound 31, sunnyInCompound 31, smileInCompound 31, yourSunnySmile 31 ]
                in
                tagSection section
                    |> Query.fromHtml
                    |> Query.children [ tag "span" ]
                    |> Query.first
                    |> Query.has [ tag "b", id "your sunny smile", text "твоя солнечная улыбка" ]
        , test "with one unglossed word and one glossed compound word (two word)" <|
            \_ ->
                let
                    section =
                        makeSection
                            "твоя солнечная улыбка"
                            [ sunnyInCompound 32, smileInCompound 32, sunnySmile 32 ]
                in
                tagSection section
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ text "твоя" ]
                        , Query.children [ tag "span" ]
                            >> Query.first
                            >> Query.has [ tag "b", id "sunny smile", text "солнечная улыбка" ]
                        ]
        , test "with repeated words, both glossed, first alone and second in compound word (two word)" <|
            \_ ->
                let
                    section =
                        makeSection
                            "улыбка солнечная улыбка"
                            [ sunnyInCompound 33, grinAndSmileInCompound 33, sunnySmile 33 ]
                in
                tagSection section
                    |> Query.fromHtml
                    |> Query.children [ tag "span" ]
                    |> Expect.all
                        [ Query.index 0
                            >> Query.has [ tag "b", id "grin", text "улыбка" ]
                        , Query.index 1
                            >> Query.has [ tag "b", id "sunny smile", text "солнечная улыбка" ]
                        ]
        , test "with repeated words, both glossed, first in compound word (two word) and second alone" <|
            \_ ->
                let
                    section =
                        makeSection
                            "солнечная улыбка улыбка"
                            [ sunnyInCompound 34, smileInCompoundAndGrin 34, sunnySmile 34 ]
                in
                tagSection section
                    |> Query.fromHtml
                    |> Query.children [ tag "span" ]
                    |> Expect.all
                        [ Query.index 0
                            >> Query.has [ tag "b", id "sunny smile", text "солнечная улыбка" ]
                        , Query.index 1
                            >> Query.has [ tag "b", id "grin", text "улыбка" ]
                        ]
        , test "with repeated words, both glossed, both in compound words (two word and three word)" <|
            \_ ->
                let
                    section =
                        makeSection
                            "солнечная улыбка, твоя солнечная улыбка"
                            [ yourInCompound 36
                            , sunnyInTwoCompounds 35 36
                            , smileInTwoCompounds 35 36
                            , sunnySmile 35
                            , yourSunnySmile 36
                            ]
                in
                tagSection section
                    |> Query.fromHtml
                    |> Query.children [ tag "span" ]
                    |> Expect.all
                        [ Query.index 0
                            >> Expect.all
                                [ Query.has [ tag "b", id "sunny smile", text "солнечная улыбка" ]
                                , Query.has [ text "," ]
                                ]
                        , Query.index 1
                            >> Query.has [ tag "b", id "your sunny smile", text "твоя солнечная улыбка" ]
                        ]
        , test "with repeated words, both glossed, both in compound words (three word and two word)" <|
            \_ ->
                let
                    section =
                        makeSection
                            "твоя солнечная улыбка, солнечная улыбка"
                            [ yourInCompound 37
                            , sunnyInTwoCompounds 37 38
                            , smileInTwoCompounds 37 38
                            , yourSunnySmile 37
                            , sunnySmile 38
                            ]
                in
                tagSection section
                    |> Query.fromHtml
                    |> Query.children [ tag "span" ]
                    |> Expect.all
                        [ Query.index 0
                            >> Expect.all
                                [ Query.has [ tag "b", id "your sunny smile", text "твоя солнечная улыбка" ]
                                , Query.has [ text "," ]
                                ]
                        , Query.index 1
                            >> Query.has [ tag "b", id "sunny smile", text "солнечная улыбка" ]
                        ]
        , test "with repeated words, both glossed and in compound words (two word), different translations" <|
            \_ ->
                let
                    section =
                        makeSection
                            "солнечная улыбка, солнечная улыбка"
                            [ sunnyAndSolarInCompounds 39 40
                            , smileAndGrinInCompounds 39 40
                            , sunnySmileAndSolarGrin 39 40
                            ]
                in
                tagSection section
                    |> Query.fromHtml
                    |> Query.children [ tag "span" ]
                    |> Expect.all
                        [ Query.index 0
                            >> Expect.all
                                [ Query.has [ tag "b", id "sunny smile", text "солнечная улыбка" ]
                                , Query.has [ text "," ]
                                ]
                        , Query.index 1
                            >> Query.has [ tag "b", id "solar grin", text "солнечная улыбка" ]
                        ]
        ]


invalidWords : Test
invalidWords =
    describe "Tags words in a section with invalid words"
        [ test "one invalid word" <|
            \_ ->
                let
                    section =
                        makeSection
                            "time"
                            []
                in
                tagSection section
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.hasNot [ tag "span", tag "b" ]
                        , Query.has [ text "time" ]
                        ]
        , test "one invalid word and one glossed word" <|
            \_ ->
                let
                    section =
                        makeSection
                            "улыбка time"
                            [ smile ]
                in
                tagSection section
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.children [ tag "span" ]
                            >> Query.first
                            >> Query.has [ tag "b", id "smile", text "улыбка" ]
                        , Query.has [ text "time" ]
                        ]
        , test "two invalid words surrounding one glossed word" <|
            \_ ->
                let
                    section =
                        makeSection
                            "your улыбка time"
                            [ smile ]
                in
                tagSection section
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ text "your" ]
                        , Query.children [ tag "span" ]
                            >> Query.first
                            >> Query.has [ tag "b", id "smile", text "улыбка" ]
                        , Query.has [ text "time" ]
                        ]
        , test "two invalid words surrounding one glossed compound word" <|
            \_ ->
                let
                    section =
                        makeSection
                            "your солнечная улыбка time"
                            [ sunnyInCompound 41, smileInCompound 41, sunnySmile 41 ]
                in
                tagSection section
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ text "your" ]
                        , Query.children [ tag "span" ]
                            >> Query.first
                            >> Query.has [ tag "b", id "sunny smile", text "солнечная улыбка" ]
                        , Query.has [ text "time" ]
                        ]
        , test "invalid word, glossed word, invalid word, glossed compound word" <|
            \_ ->
                let
                    section =
                        makeSection
                            "solar улыбка, your солнечная улыбка"
                            [ sunnyInCompound 42, grinAndSmileInCompound 42, sunnySmile 42 ]
                in
                tagSection section
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ text "solar" ]
                        , Query.children [ tag "span" ]
                            >> Query.index 0
                            >> Query.has [ tag "b", id "grin", text "улыбка" ]
                        , Query.has [ text "your" ]
                        , Query.children [ tag "span" ]
                            >> Query.index 1
                            >> Query.has [ tag "b", id "sunny smile", text "солнечная улыбка" ]
                        ]
        ]


tagSection : Section -> Html msg
tagSection section =
    textSection section
        |> (\sect -> parseHtml sect.body)
        |> toTaggedHtml
            (tagWord section)
            (inCompoundWord section)
        |> Html.div []


parseHtml : String -> List Node
parseHtml htmlString =
    case Html.Parser.run htmlString of
        Ok nodes ->
            nodes

        Err err ->
            [ Html.Parser.Comment "Parser failed" ]


tagWord :
    Section
    -> Int
    -> { leadingPunctuation : String, token : String, trailingPunctuation : String }
    -> Html msg
tagWord section instance wordRecord =
    let
        textreaderTextword =
            TextReader.Section.Model.getTextWord section instance wordRecord.token
    in
    case textreaderTextword of
        Just textWord ->
            if TextReader.TextWord.hasTranslations textWord then
                Html.span []
                    [ Html.text wordRecord.leadingPunctuation
                    , Html.b [ Html.Attributes.id (translation textWord) ]
                        [ Html.text wordRecord.token
                        ]
                    , Html.text wordRecord.trailingPunctuation
                    ]

            else
                Html.text (wordRecord.leadingPunctuation ++ wordRecord.token ++ wordRecord.trailingPunctuation)

        Nothing ->
            Html.text (wordRecord.leadingPunctuation ++ wordRecord.token ++ wordRecord.trailingPunctuation)


inCompoundWord : Section -> Int -> String -> Maybe ( Int, Int, Int )
inCompoundWord section instance word =
    case TextReader.Section.Model.getTextWord section instance word of
        Just textWord ->
            case TextReader.TextWord.group textWord of
                Just group ->
                    -- Just ( group.instance, group.pos, group.length )
                    Just ( group.id, group.pos, group.length )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


translation : TextWord -> String
translation word =
    case TextReader.TextWord.translations word of
        Just translations ->
            case List.filter (\t -> t.correct_for_context) translations of
                trns :: tail ->
                    trns.text

                [] ->
                    ""

        Nothing ->
            ""



-- SECTION


makeSection : String -> List ( String, Array TextWord ) -> Section
makeSection body glossedWords =
    newSection
        { order = 0
        , body = body
        , question_count = 0
        , questions = Array.empty
        , num_of_sections = 1
        , translations =
            Dict.fromList glossedWords
        }



-- SINGLE WORD EXAMPLES


{-| IDs are used to building arrays of text words for a word token. For these test cases, the words have been
put into the correct order and the IDs are not used.
-}



-- твоя


your : ( String, Array TextWord )
your =
    ( "твоя"
    , Array.fromList
        [ TextReader.TextWord.new 0 0 "твоя" Nothing (Just [ { correct_for_context = True, text = "your" } ]) (SingleWord Nothing)
        ]
    )


yourInCompound : Int -> ( String, Array TextWord )
yourInCompound groupId =
    ( "твоя"
    , Array.fromList
        [ TextReader.TextWord.new 1
            0
            "твоя"
            Nothing
            (Just [ { correct_for_context = True, text = "your" } ])
            (SingleWord <|
                Just
                    { id = groupId
                    , instance = 0
                    , pos = 0
                    , length = 2
                    }
            )
        ]
    )



-- солнечная


sunny : ( String, Array TextWord )
sunny =
    ( "солнечная"
    , Array.fromList
        [ TextReader.TextWord.new 2 0 "солнечная" Nothing (Just [ { correct_for_context = True, text = "sunny" } ]) (SingleWord Nothing)
        ]
    )


sunnyInCompound : Int -> ( String, Array TextWord )
sunnyInCompound groupId =
    ( "солнечная"
    , Array.fromList
        [ TextReader.TextWord.new 3
            0
            "солнечная"
            Nothing
            (Just [ { correct_for_context = True, text = "sunny" } ])
            (SingleWord <|
                Just
                    { id = groupId
                    , instance = 0
                    , pos = 0
                    , length = 2
                    }
            )
        ]
    )


sunnyInTwoCompounds : Int -> Int -> ( String, Array TextWord )
sunnyInTwoCompounds groupOneId groupTwoId =
    ( "солнечная"
    , Array.fromList
        [ TextReader.TextWord.new 4
            0
            "солнечная"
            Nothing
            (Just [ { correct_for_context = True, text = "sunny" } ])
            (SingleWord <|
                Just
                    { id = groupOneId
                    , instance = 0
                    , pos = 0
                    , length = 2
                    }
            )
        , TextReader.TextWord.new 5
            1
            "солнечная"
            Nothing
            (Just [ { correct_for_context = True, text = "sunny" } ])
            (SingleWord <|
                Just
                    { id = groupTwoId
                    , instance = 0
                    , pos = 1
                    , length = 3
                    }
            )
        ]
    )


sunnyAndSolarInCompounds : Int -> Int -> ( String, Array TextWord )
sunnyAndSolarInCompounds groupOneId groupTwoId =
    ( "солнечная"
    , Array.fromList
        [ TextReader.TextWord.new 6
            0
            "солнечная"
            Nothing
            (Just [ { correct_for_context = True, text = "sunny" } ])
            (SingleWord <|
                Just
                    { id = groupOneId
                    , instance = 0
                    , pos = 0
                    , length = 2
                    }
            )
        , TextReader.TextWord.new 7
            1
            "солнечная"
            Nothing
            (Just [ { correct_for_context = True, text = "solar" } ])
            (SingleWord <|
                Just
                    { id = groupTwoId
                    , instance = 0
                    , pos = 1
                    , length = 3
                    }
            )
        ]
    )



-- улыбка


smile : ( String, Array TextWord )
smile =
    ( "улыбка"
    , Array.fromList
        [ TextReader.TextWord.new 8 0 "улыбка" Nothing (Just [ { correct_for_context = True, text = "smile" } ]) (SingleWord Nothing)
        ]
    )


grinAndSmile : ( String, Array TextWord )
grinAndSmile =
    ( "улыбка"
    , Array.fromList
        [ TextReader.TextWord.new 9 0 "улыбка" Nothing (Just [ { correct_for_context = True, text = "grin" } ]) (SingleWord Nothing)
        , TextReader.TextWord.new 10 1 "улыбка" Nothing (Just [ { correct_for_context = True, text = "smile" } ]) (SingleWord Nothing)
        ]
    )


smileInCompound : Int -> ( String, Array TextWord )
smileInCompound groupId =
    ( "улыбка"
    , Array.fromList
        [ TextReader.TextWord.new 11
            0
            "улыбка"
            Nothing
            (Just [ { correct_for_context = True, text = "smile" } ])
            (SingleWord <|
                Just
                    { id = groupId
                    , instance = 0
                    , pos = 1
                    , length = 2
                    }
            )
        ]
    )


smileInTwoCompounds : Int -> Int -> ( String, Array TextWord )
smileInTwoCompounds groupOneId groupTwoId =
    ( "улыбка"
    , Array.fromList
        [ TextReader.TextWord.new 12
            0
            "улыбка"
            Nothing
            (Just [ { correct_for_context = True, text = "smile" } ])
            (SingleWord <|
                Just
                    { id = groupOneId
                    , instance = 0
                    , pos = 1
                    , length = 2
                    }
            )
        , TextReader.TextWord.new 13
            1
            "улыбка"
            Nothing
            (Just [ { correct_for_context = True, text = "smile" } ])
            (SingleWord <|
                Just
                    { id = groupTwoId
                    , instance = 0
                    , pos = 2
                    , length = 3
                    }
            )
        ]
    )


grinAndSmileInCompound : Int -> ( String, Array TextWord )
grinAndSmileInCompound groupId =
    ( "улыбка"
    , Array.fromList
        [ TextReader.TextWord.new 14 0 "улыбка" Nothing (Just [ { correct_for_context = True, text = "grin" } ]) (SingleWord Nothing)
        , TextReader.TextWord.new 15
            1
            "улыбка"
            Nothing
            (Just [ { correct_for_context = True, text = "smile" } ])
            (SingleWord <|
                Just
                    { id = groupId
                    , instance = 0
                    , pos = 1
                    , length = 2
                    }
            )
        ]
    )


smileInCompoundAndGrin : Int -> ( String, Array TextWord )
smileInCompoundAndGrin groupId =
    ( "улыбка"
    , Array.fromList
        [ TextReader.TextWord.new 16
            0
            "улыбка"
            Nothing
            (Just [ { correct_for_context = True, text = "smile" } ])
            (SingleWord <|
                Just
                    { id = groupId
                    , instance = 0
                    , pos = 1
                    , length = 2
                    }
            )
        , TextReader.TextWord.new 17 1 "улыбка" Nothing (Just [ { correct_for_context = True, text = "grin" } ]) (SingleWord Nothing)
        ]
    )


smileAndGrinInCompounds : Int -> Int -> ( String, Array TextWord )
smileAndGrinInCompounds groupOneId groupTwoId =
    ( "улыбка"
    , Array.fromList
        [ TextReader.TextWord.new 18
            1
            "улыбка"
            Nothing
            (Just [ { correct_for_context = True, text = "smile" } ])
            (SingleWord <|
                Just
                    { id = groupOneId
                    , instance = 0
                    , pos = 1
                    , length = 2
                    }
            )
        , TextReader.TextWord.new 19
            1
            "улыбка"
            Nothing
            (Just [ { correct_for_context = True, text = "grin" } ])
            (SingleWord <|
                Just
                    { id = groupTwoId
                    , instance = 0
                    , pos = 1
                    , length = 2
                    }
            )
        ]
    )



-- COMPOUND WORD EXAMPLES


{-| The group instance, pos, and length are ignored in the current implementation.
The group id is all we need to match words with their group.
-}



-- солнечная улыбка


sunnySmile : Int -> ( String, Array TextWord )
sunnySmile groupId =
    ( "солнечная улыбка"
    , Array.fromList
        [ TextReader.TextWord.new groupId
            0
            "солнечная улыбка"
            Nothing
            (Just [ { correct_for_context = True, text = "sunny smile" } ])
            CompoundWord
        ]
    )


sunnySmileAndSolarGrin : Int -> Int -> ( String, Array TextWord )
sunnySmileAndSolarGrin groupOneId groupTwoId =
    ( "солнечная улыбка"
    , Array.fromList
        [ TextReader.TextWord.new groupOneId
            0
            "солнечная улыбка"
            Nothing
            (Just [ { correct_for_context = True, text = "sunny smile" } ])
            CompoundWord
        , TextReader.TextWord.new groupTwoId
            1
            "солнечная улыбка"
            Nothing
            (Just [ { correct_for_context = True, text = "solar grin" } ])
            CompoundWord
        ]
    )



-- твоя солнечная улыбка


yourSunnySmile : Int -> ( String, Array TextWord )
yourSunnySmile groupId =
    ( "твоя солнечная улыбка"
    , Array.fromList
        [ TextReader.TextWord.new groupId
            0
            "твоя солнечная улыбка"
            Nothing
            (Just [ { correct_for_context = True, text = "your sunny smile" } ])
            CompoundWord
        ]
    )
