module Text.Translations.Encode exposing
    ( deleteTextTranslationEncode
    , grammemesEncoder
    , newTextTranslationEncoder
    , textTranslationAsCorrectEncoder
    , textTranslationsMergeEncoder
    , textWordMergeEncoder
    )

import Dict exposing (Dict)
import Json.Encode as Encode
import Text.Translations exposing (Translation)
import Text.Translations.TextWord exposing (TextWord)


textTranslationEncoder : Translation -> Encode.Value
textTranslationEncoder textTranslation =
    Encode.object
        [ ( "id", Encode.int textTranslation.id )
        , ( "text", Encode.string textTranslation.text )
        , ( "correct_for_context", Encode.bool textTranslation.correct_for_context )
        ]


textTranslationsMergeEncoder : List Translation -> List TextWord -> Encode.Value
textTranslationsMergeEncoder textWordTranslations textWords =
    Encode.object
        [ ( "words"
          , Encode.list <|
                List.map
                    (\tw ->
                        Encode.object
                            [ ( "id", Encode.int (Text.Translations.TextWord.idToInt tw) )
                            , ( "word_type", Encode.string (Text.Translations.TextWord.wordType tw) )
                            ]
                    )
                    textWords
          )
        , ( "translations"
          , Encode.list <|
                List.map
                    (\twt ->
                        Encode.object
                            [ ( "correct_for_context", Encode.bool twt.correct_for_context )
                            , ( "phrase", Encode.string twt.text )
                            ]
                    )
                    textWordTranslations
          )
        ]


textTranslationsEncoder : List Translation -> Encode.Value
textTranslationsEncoder textTranslations =
    Encode.list (List.map textTranslationEncoder textTranslations)


textTranslationAsCorrectEncoder : Translation -> Encode.Value
textTranslationAsCorrectEncoder textTranslation =
    Encode.object
        [ ( "id", Encode.int textTranslation.id )
        , ( "correct_for_context", Encode.bool textTranslation.correct_for_context )
        ]


textWordMergeEncoder : List TextWord -> Encode.Value
textWordMergeEncoder textWords =
    Encode.list
        (List.map (\textWord -> Encode.int (Text.Translations.TextWord.idToInt textWord)) textWords)


newTextTranslationEncoder : String -> Bool -> Encode.Value
newTextTranslationEncoder translation correct_for_context =
    Encode.object
        [ ( "phrase", Encode.string translation )
        , ( "correct_for_context", Encode.bool correct_for_context )
        ]


deleteTextTranslationEncode : Int -> Encode.Value
deleteTextTranslationEncode translationId =
    Encode.object
        [ ( "id", Encode.int translationId )
        ]


encodeDict : (comparable -> String) -> (v -> Encode.Value) -> Dict comparable v -> Encode.Value
encodeDict kName vValue dict =
    Encode.object <|
        List.map (\( k, v ) -> ( kName k, vValue v )) (Dict.toList dict)


grammemesEncoder : TextWord -> Dict String String -> Encode.Value
grammemesEncoder textWord grammemes =
    Encode.object
        [ ( "word_type", Encode.string (Text.Translations.TextWord.wordType textWord) )
        , ( "grammemes", encodeDict identity Encode.string grammemes )
        ]
