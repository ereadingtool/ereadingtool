module Text.Translations.Encode exposing (..)

import Text.Translations exposing (..)

import Text.Translations.TextWord exposing (TextWord)

import Json.Encode as Encode

import Dict exposing (Dict)


textTranslationEncoder : Translation -> Encode.Value
textTranslationEncoder text_translation =
  Encode.object [
    ("id", Encode.int text_translation.id)
  , ("text", Encode.string text_translation.text)
  , ("correct_for_context", Encode.bool text_translation.correct_for_context)
  ]

textTranslationsMergeEncoder : List Translation -> List TextWord -> Encode.Value
textTranslationsMergeEncoder text_word_translations text_words =
  Encode.object [
    ( "words"
    ,  Encode.list
    <| List.map (\tw ->
          Encode.object [
            ("id", Encode.int (Text.Translations.TextWord.id tw))
          , ("word_type", Encode.string (Text.Translations.TextWord.wordType tw))
          ]
       ) text_words)
  , ( "translations"
    , Encode.list <| List.map
        (\twt ->
          Encode.object [
            ("correct_for_context", Encode.bool twt.correct_for_context)
          , ("phrase", Encode.string twt.text)
          ]) text_word_translations)
  ]

textTranslationsEncoder : List Translation -> Encode.Value
textTranslationsEncoder text_translations =
  Encode.list (List.map textTranslationEncoder text_translations)

textTranslationAsCorrectEncoder : Translation -> Encode.Value
textTranslationAsCorrectEncoder text_translation =
  Encode.object [
    ("id", Encode.int text_translation.id)
  , ("correct_for_context", Encode.bool text_translation.correct_for_context)
  ]

textWordMergeEncoder : List TextWord -> Encode.Value
textWordMergeEncoder text_words =
  Encode.list
    (List.map (\text_word -> Encode.int (Text.Translations.TextWord.id text_word)) text_words)

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

encodeDict : (comparable -> String) -> (v -> Encode.Value) -> Dict comparable v -> Encode.Value
encodeDict k_name v_value dict =
  Encode.object
    <| List.map (\(k, v) -> (k_name k, v_value v)) (Dict.toList dict)

grammemesEncoder : TextWord -> Dict String String -> Encode.Value
grammemesEncoder text_word grammemes =
  Encode.object [
    ("word_type", Encode.string (Text.Translations.TextWord.wordType text_word))
  , ("grammemes", encodeDict identity Encode.string grammemes)
  ]
