module Text.Translations.Decode exposing
    ( Flashcards
    , TextWord
    , TextWordMergeResp
    , TextWordTranslationDeleteResp
    , grammemesDecoder
    , textGroupDetailsDecoder
    , textTranslationRemoveRespDecoder
    , textTranslationUpdateRespDecoder
    , textWordDictInstancesDecoder
    , textWordInstanceDecoder
    , textWordInstancesDecoder
    , textWordMergeDecoder
    , wordDecoder
    , wordsDecoder
    )

import Array exposing (Array)
import Dict exposing (Dict)
import Json.Decode
import Json.Decode.Pipeline exposing (required)
import Text.Translations exposing (..)
import Text.Translations.TextWord
import Text.Translations.Word.Kind
import TextReader.TextWord
import Util


type alias TextWord =
    { phrase : Phrase, grammemes : List ( String, String ), translation : Maybe String }


type alias Flashcards =
    Dict Phrase TextReader.TextWord.TextWord


type alias TextWords =
    Dict Phrase TextWord


type alias TextWordTranslationDeleteResp =
    { text_word : Text.Translations.TextWord.TextWord
    , translation : Translation
    , deleted : Bool
    }


type alias TextWordMergeResp =
    { phrase : String
    , section : SectionNumber
    , instance : Int
    , text_words : List Text.Translations.TextWord.TextWord
    , grouped : Bool
    , error : Maybe String
    }


wordValuesDecoder : Json.Decode.Decoder WordValues
wordValuesDecoder =
    Json.Decode.succeed WordValues
        |> required "grammemes" (Json.Decode.map Dict.fromList grammemesDecoder)
        |> required "translations" (Json.Decode.nullable (Json.Decode.list Json.Decode.string))


wordsDecoder : Json.Decode.Decoder Words
wordsDecoder =
    Json.Decode.dict wordValuesDecoder


textWordMergeDecoder : Json.Decode.Decoder TextWordMergeResp
textWordMergeDecoder =
    Json.Decode.succeed TextWordMergeResp
        |> required "phrase" Json.Decode.string
        |> required "section" (Json.Decode.map SectionNumber Json.Decode.int)
        |> required "instance" Json.Decode.int
        |> required "text_words" textWordInstancesDecoder
        |> required "grouped" Json.Decode.bool
        |> required "error" (Json.Decode.nullable Json.Decode.string)


textTranslationUpdateRespDecoder : Json.Decode.Decoder ( Text.Translations.TextWord.TextWord, Translation )
textTranslationUpdateRespDecoder =
    Json.Decode.map2 (\a b -> ( a, b ))
        (Json.Decode.field "text_word" textWordInstanceDecoder)
        (Json.Decode.field "translation" textWordTranslationsDecoder)


textTranslationRemoveRespDecoder : Json.Decode.Decoder TextWordTranslationDeleteResp
textTranslationRemoveRespDecoder =
    Json.Decode.succeed TextWordTranslationDeleteResp
        |> required "text_word" textWordInstanceDecoder
        |> required "translation" textWordTranslationsDecoder
        |> required "deleted" Json.Decode.bool


textWordDictInstancesDecoder : Json.Decode.Decoder (Array (Dict Text.Translations.Word (Array Text.Translations.TextWord.TextWord)))
textWordDictInstancesDecoder =
    Json.Decode.array (Json.Decode.dict (Json.Decode.array textWordInstanceDecoder))


textWordInstancesDecoder : Json.Decode.Decoder (List Text.Translations.TextWord.TextWord)
textWordInstancesDecoder =
    Json.Decode.list textWordInstanceDecoder


textWordTranslationsDecoder : Json.Decode.Decoder Translation
textWordTranslationsDecoder =
    Json.Decode.succeed Translation
        |> required "id" Json.Decode.int
        |> required "endpoint" Json.Decode.string
        |> required "correct_for_context" Json.Decode.bool
        |> required "text" Json.Decode.string


textGroupDetailsDecoder : Json.Decode.Decoder TextGroupDetails
textGroupDetailsDecoder =
    Json.Decode.succeed TextGroupDetails
        |> required "id" Json.Decode.int
        |> required "instance" Json.Decode.int
        |> required "pos" Json.Decode.int
        |> required "length" Json.Decode.int


wordDecoder : Json.Decode.Decoder Text.Translations.Word.Kind.WordKind
wordDecoder =
    Json.Decode.field "word_type" Json.Decode.string
        |> Json.Decode.andThen wordHelpDecoder


wordHelpDecoder : String -> Json.Decode.Decoder Text.Translations.Word.Kind.WordKind
wordHelpDecoder wordType =
    case wordType of
        "single" ->
            Json.Decode.field "group"
                (Json.Decode.map Text.Translations.Word.Kind.SingleWord (Json.Decode.nullable textGroupDetailsDecoder))

        "compound" ->
            Json.Decode.succeed Text.Translations.Word.Kind.CompoundWord

        _ ->
            Json.Decode.fail "Unsupported word type"


textWordEndpointsDecoder : Json.Decode.Decoder Text.Translations.TextWord.Endpoints
textWordEndpointsDecoder =
    Json.Decode.succeed Text.Translations.TextWord.Endpoints
        |> required "text_word" Json.Decode.string
        |> required "translations" Json.Decode.string


textWordInstanceDecoder : Json.Decode.Decoder Text.Translations.TextWord.TextWord
textWordInstanceDecoder =
    Json.Decode.map8 Text.Translations.TextWord.new
        (Json.Decode.field "id" (Json.Decode.map TextWordId Json.Decode.int))
        (Json.Decode.field "text_section" (Json.Decode.map SectionNumber Json.Decode.int))
        (Json.Decode.field "instance" Json.Decode.int)
        (Json.Decode.field "phrase" Json.Decode.string)
        (Json.Decode.field "grammemes" (Json.Decode.nullable (Json.Decode.map Dict.fromList grammemesDecoder)))
        (Json.Decode.field "translations" (Json.Decode.nullable (Json.Decode.list textWordTranslationsDecoder)))
        wordDecoder
        (Json.Decode.field "endpoints" textWordEndpointsDecoder)


grammemesDecoder : Json.Decode.Decoder (List ( String, String ))
grammemesDecoder =
    Json.Decode.list Util.stringTupleDecoder


textWordDecoder : Json.Decode.Decoder TextWord
textWordDecoder =
    Json.Decode.succeed TextWord
        |> required "phrase" Json.Decode.string
        |> required "grammemes" grammemesDecoder
        |> required "translation" (Json.Decode.nullable Json.Decode.string)
