module Text.Encode exposing (..)

import Text.Model
import Text.Section.Encode exposing (textSectionsEncoder)

import Json.Encode as Encode

textEncoder : Text.Model.Text -> Encode.Value
textEncoder text =
  let
    conclusion =
      (case text.conclusion of
        Just conclusion ->
          [("conclusion", Encode.string conclusion)]
        Nothing ->
          [])
  in
    Encode.object <| [
        ("introduction", Encode.string text.introduction)
      , ("title", Encode.string text.title)
      , ("source", Encode.string text.source)
      , ("author", Encode.string text.author)
      , ("difficulty", Encode.string text.difficulty)
      , ("text_sections", textSectionsEncoder text.sections)
      , ("tags", Encode.list
          (case text.tags of
            Just tags -> List.map (\tag -> Encode.string tag) tags
            _ -> []))
    ] ++ conclusion

textTranslationEncoder : Text.Model.TextWordTranslation -> Encode.Value
textTranslationEncoder text_translation =
  Encode.object [
    ("id", Encode.int text_translation.id)
  , ("text", Encode.string text_translation.text)
  , ("correct_for_context", Encode.bool text_translation.correct_for_context)
  ]

textTranslationsEncoder : List Text.Model.TextWordTranslation -> Encode.Value
textTranslationsEncoder text_translations =
  Encode.list (List.map textTranslationEncoder text_translations)

textTranslationAsCorrectEncoder : Text.Model.TextWordTranslation -> Encode.Value
textTranslationAsCorrectEncoder text_translation =
  Encode.object [
    ("id", Encode.int text_translation.id)
  , ("correct_for_context", Encode.bool text_translation.correct_for_context)
  ]

newTextTranslationEncoder : String -> Encode.Value
newTextTranslationEncoder translation =
  Encode.object [
    ("phrase", Encode.string translation)
  ]

deleteTextTranslationEncode : Int -> Encode.Value
deleteTextTranslationEncode translation_id =
  Encode.object [
    ("id", Encode.int translation_id)
  ]