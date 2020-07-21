module InstructorAdmin.Text.Translations.Word.Instance.Encode exposing (textWordAddEncoder)

import InstructorAdmin.Text.Translations.Word.Instance as TranslationsWordInstance exposing (WordInstance)
import Json.Encode as Encode


textWordAddEncoder : Int -> WordInstance -> Encode.Value
textWordAddEncoder textId wordInstance =
    Encode.object
        [ ( "text", Encode.int textId )
        , ( "text_section", Encode.int (TranslationsWordInstance.wordInstanceSectionNumberToInt wordInstance) )
        , ( "instance", Encode.int (TranslationsWordInstance.instance wordInstance) )
        , ( "phrase", Encode.string (TranslationsWordInstance.word wordInstance) )
        ]
