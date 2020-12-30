module Word.Tests exposing (all)

import Expect
import Fuzz exposing (Fuzzer, string)
import Parser exposing (run)
import Test exposing (..)
import Text.Section.Words.Tag exposing (Word(..), WordRecord, parse)


all : Test
all =
    describe "Parses Russian words removing punctuation where appropriate for glossing"
        [ describe
            "Removes a single punctuation mark"
            [ test "Removes trailing ." <|
                \_ ->
                    run parse "назревал."
                        |> Expect.equal (Ok <| WordRecord "" (ValidWord "назревал") ".")
            , test "Removes trailing ," <|
                \_ ->
                    run parse "низкие,"
                        |> Expect.equal (Ok <| WordRecord "" (ValidWord "низкие") ",")
            , test "Removes trailing ?" <|
                \_ ->
                    run parse "волну?"
                        |> Expect.equal (Ok <| WordRecord "" (ValidWord "волну") "?")
            , test "Removes trailing :" <|
                \_ ->
                    run parse "смешалось:"
                        |> Expect.equal (Ok <| WordRecord "" (ValidWord "смешалось") ":")
            , test "Removes trailing ;" <|
                \_ ->
                    run parse "смешалось;"
                        |> Expect.equal (Ok <| WordRecord "" (ValidWord "смешалось") ";")
            , test "Removes /" <|
                \_ ->
                    "/" |> Expect.equal "/"
            , test "Removes trailing !" <|
                \_ ->
                    run parse "смешалось!"
                        |> Expect.equal (Ok <| WordRecord "" (ValidWord "смешалось") "!")
            , test "Removes \\" <|
                \_ ->
                    "\\" |> Expect.equal "\\"
            , test "Removes leading «" <|
                \_ ->
                    run parse "«Меры"
                        |> Expect.equal (Ok <| WordRecord "«" (ValidWord "Меры") "")
            , test "Removes trailing »" <|
                \_ ->
                    run parse "Голливуда»"
                        |> Expect.equal (Ok <| WordRecord "" (ValidWord "Голливуда") "»")
            , test "Retains - in the middle of a parse " <|
                \_ ->
                    run parse "из-за"
                        |> Expect.equal (Ok <| WordRecord "" (ValidWord "из-за") "")
            , test "Removes leading (" <|
                \_ ->
                    run parse "(та"
                        |> Expect.equal (Ok <| WordRecord "(" (ValidWord "та") "")
            , test "Removes trailing )" <|
                \_ ->
                    run parse "та)"
                        |> Expect.equal (Ok <| WordRecord "" (ValidWord "та") ")")
            , test "Removes leading [" <|
                \_ ->
                    run parse "[та"
                        |> Expect.equal (Ok <| WordRecord "[" (ValidWord "та") "")
            , test "Removes trailing ]" <|
                \_ ->
                    run parse "та]"
                        |> Expect.equal (Ok <| WordRecord "" (ValidWord "та") "]")
            , test "Removes leading {" <|
                \_ ->
                    run parse "{та"
                        |> Expect.equal (Ok <| WordRecord "{" (ValidWord "та") "")
            , test "Removes trailing }" <|
                \_ ->
                    run parse "та}"
                        |> Expect.equal (Ok <| WordRecord "" (ValidWord "та") "}")
            , test "Removes leading <" <|
                \_ ->
                    run parse "<та"
                        |> Expect.equal (Ok <| WordRecord "<" (ValidWord "та") "")
            , test "Removes trailing >" <|
                \_ ->
                    run parse "та>"
                        |> Expect.equal (Ok <| WordRecord "" (ValidWord "та") ">")
            , test "Removes trailing …" <|
                \_ ->
                    run parse "та…"
                        |> Expect.equal (Ok <| WordRecord "" (ValidWord "та") "…")
            ]
        , describe
            "Removes simple enclosing punctuation"
            [ test "Removes enclosing « »" <|
                \_ ->
                    run parse "«Мосфильма»"
                        |> Expect.equal (Ok <| WordRecord "«" (ValidWord "Мосфильма") "»")
            , test "Removes enclosiong ( )" <|
                \_ ->
                    run parse "(КГИ)"
                        |> Expect.equal (Ok <| WordRecord "(" (ValidWord "КГИ") ")")
            , test "Removes enclosiong „ “" <|
                \_ ->
                    run parse "„КГИ“"
                        |> Expect.equal (Ok <| WordRecord "„" (ValidWord "КГИ") "“")
            , test "Removes enclosiong [ ]" <|
                \_ ->
                    run parse "[КГИ]"
                        |> Expect.equal (Ok <| WordRecord "[" (ValidWord "КГИ") "]")
            , test "Removes enclosiong { }" <|
                \_ ->
                    run parse "{КГИ}"
                        |> Expect.equal (Ok <| WordRecord "{" (ValidWord "КГИ") "}")
            , test "Removes enclosiong < >" <|
                \_ ->
                    run parse "<КГИ>"
                        |> Expect.equal (Ok <| WordRecord "<" (ValidWord "КГИ") ">")
            ]
        , describe
            "Removes complex trailing punctuation"
            [ test "Removes trailing )," <|
                \_ ->
                    run parse "та),"
                        |> Expect.equal (Ok <| WordRecord "" (ValidWord "та") "),")
            , test "Removes trailing »," <|
                \_ ->
                    run parse "Голливуда»,"
                        |> Expect.equal (Ok <| WordRecord "" (ValidWord "Голливуда") "»,")
            , test "Removes trailing »." <|
                \_ ->
                    run parse "Голливуда»."
                        |> Expect.equal (Ok <| WordRecord "" (ValidWord "Голливуда") "».")
            ]
        , describe
            "Removes complex enclosing punctuation"
            [ test "Removes enclosing ( ," <|
                \_ ->
                    run parse "(та,"
                        |> Expect.equal (Ok <| WordRecord "(" (ValidWord "та") ",")
            , test "Removes enclosing « »." <|
                \_ ->
                    run parse "«Интерфакс»."
                        |> Expect.equal (Ok <| WordRecord "«" (ValidWord "Интерфакс") "».")
            , test "Removes enclosing « ». and preserves - in middle of a word" <|
                \_ ->
                    run parse "«амур-тужур»."
                        |> Expect.equal (Ok <| WordRecord "«" (ValidWord "амур-тужур") "».")
            ]
        , describe
            "Ignores invalid  words"
            [ test "Ignores (Times" <|
                \_ ->
                    run parse "(Times"
                        |> Expect.equal (Ok <| WordRecord "(" (InvalidWord "Times") "")
            , test "Ignores —" <|
                \_ ->
                    run parse "—"
                        |> Expect.equal (Ok <| WordRecord "" (InvalidWord "—") "")
            , test "Ignores …" <|
                \_ ->
                    run parse "…"
                        |> Expect.equal (Ok <| WordRecord "" (InvalidWord "") "…")
            ]
        ]
