module Text.Translations.Word.Instance.Encode exposing (textWordAddEncoder)

import Json.Encode as Encode
import Text.Translations.Word.Instance exposing (WordInstance)


textWordAddEncoder : Int -> WordInstance -> Encode.Value
textWordAddEncoder textId wordInstance =
    Encode.object
        [ ( "text", Encode.int textId )
        , ( "text_section", Encode.int (Text.Translations.Word.Instance.wordInstanceSectionNumberToInt wordInstance) )
        , ( "instance", Encode.int (Text.Translations.Word.Instance.instance wordInstance) )
        , ( "phrase", Encode.string (Text.Translations.Word.Instance.word wordInstance) )
        ]
