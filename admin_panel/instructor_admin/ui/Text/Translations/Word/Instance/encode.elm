module Text.Translations.Word.Instance.Encode exposing (..)

import Text.Translations.Word.Instance exposing (WordInstance)

import Json.Encode as Encode


textWordAddEncoder : Int -> WordInstance -> Encode.Value
textWordAddEncoder text_id word_instance =
  Encode.object [
    ("text", Encode.int text_id)
  , ("text_section", Encode.int (Text.Translations.Word.Instance.wordInstanceSectionNumberToInt word_instance))
  , ("instance", Encode.int (Text.Translations.Word.Instance.instance word_instance))
  , ("phrase", Encode.string (Text.Translations.Word.Instance.word word_instance))
  ]
