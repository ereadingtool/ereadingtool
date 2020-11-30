module User.Student.Profile.Decode exposing (DeleteMe)

import InstructorAdmin.Text.Translations exposing (Phrase)
import Json.Decode
import Json.Decode.Pipeline exposing (required)
import Text.Translations.Decode as TextTranslationsDecode
import TextReader.Section.Decode
import TextReader.TextWord
import Utils exposing (stringTupleDecoder)


type DeleteMe
    = DeleteMe



{- These decoders are not currently used, but may have been important for the Flashcards list
   in the student profile. They are left here in case they are needed to bring in Flashcards.
-}


textWordParamsDecoder : Json.Decode.Decoder TextReader.TextWord.TextWordParams
textWordParamsDecoder =
    Json.Decode.succeed TextReader.TextWord.TextWordParams
        |> required "id" Json.Decode.int
        |> required "instance" Json.Decode.int
        |> required "phrase" Json.Decode.string
        |> required "grammemes" (Json.Decode.nullable (Json.Decode.list stringTupleDecoder))
        |> required "translations" TextReader.Section.Decode.textWordTranslationsDecoder
        |> required "word"
            (Json.Decode.map2 (\a b -> ( a, b ))
                (Json.Decode.index 0 Json.Decode.string)
                (Json.Decode.index 1 (Json.Decode.nullable TextTranslationsDecode.textGroupDetailsDecoder))
            )


wordTextWordDecoder : Json.Decode.Decoder (Maybe (List ( Phrase, TextReader.TextWord.TextWordParams )))
wordTextWordDecoder =
    Json.Decode.nullable
        (Json.Decode.list
            (Json.Decode.map2 (\a b -> ( a, b ))
                (Json.Decode.index 0 Json.Decode.string)
                (Json.Decode.index 1 textWordParamsDecoder)
            )
        )
