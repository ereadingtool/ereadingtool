module TextReader.Section.Decode exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)
import InstructorAdmin.Text.Translations exposing (..)
import Text.Translations.Decode as TranslationsDecode
import Json.Decode
import Json.Decode.Pipeline exposing (required)
import TextReader.Question.Decode
import TextReader.Section.Model exposing (Section, TextSection, Words)
import TextReader.TextWord


sectionDecoder : Json.Decode.Decoder Section
sectionDecoder =
    Json.Decode.map TextReader.Section.Model.newSection textSectionDecoder


textWordTranslationDecoder : Json.Decode.Decoder TextReader.TextWord.Translation
textWordTranslationDecoder =
    Json.Decode.succeed TextReader.TextWord.Translation
        |> required "correct_for_context" Json.Decode.bool
        |> required "text" Json.Decode.string


textWordTranslationsDecoder : Json.Decode.Decoder (Maybe (List TextReader.TextWord.Translation))
textWordTranslationsDecoder =
    Json.Decode.nullable (Json.Decode.list textWordTranslationDecoder)


textWordInstanceDecoder : Json.Decode.Decoder TextReader.TextWord.TextWord
textWordInstanceDecoder =
    Json.Decode.map6 TextReader.TextWord.new
        (Json.Decode.field "id" Json.Decode.int)
        (Json.Decode.field "instance" Json.Decode.int)
        (Json.Decode.field "phrase" Json.Decode.string)
        (Json.Decode.field "grammemes"
            (Json.Decode.nullable (Json.Decode.map Dict.fromList TranslationsDecode.grammemesDecoder))
        )
        (Json.Decode.field "translations" textWordTranslationsDecoder)
        TranslationsDecode.wordDecoder


textWordDictInstancesDecoder : Json.Decode.Decoder (Dict Phrase (Array TextReader.TextWord.TextWord))
textWordDictInstancesDecoder =
    Json.Decode.dict (Json.Decode.array textWordInstanceDecoder)


textSectionDecoder : Json.Decode.Decoder TextSection
textSectionDecoder =
    Json.Decode.succeed TextSection
        |> required "order" Json.Decode.int
        |> required "body" Json.Decode.string
        |> required "question_count" Json.Decode.int
        |> required "questions" TextReader.Question.Decode.questionsDecoder
        |> required "num_of_sections" Json.Decode.int
        |> required "translations" textWordDictInstancesDecoder
