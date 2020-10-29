module TextReader.TextWord exposing
    ( TextWord
    , TextWordParams
    , Translation
    , grammemesToString
    , group
    , hasTranslations
    , new
    , newFromParams
    , phrase
    , translations
    )

import Dict exposing (Dict)
import InstructorAdmin.Text.Translations exposing (..)
import Text.Translations.TextWord as TranslationsTextWord
import Text.Translations.Word.Kind as TranslationsWordKind


type alias Translation =
    { correct_for_context : Bool
    , text : String
    }


type alias Translations =
    List Translation


type alias TextWordParams =
    { id : Int
    , instance : Int
    , phrase : String
    , grammemes : Maybe (List ( String, String ))
    , translations : Maybe Translations
    , word : ( String, Maybe TextGroupDetails )
    }


type TextWord
    = TextWord Int Instance Phrase (Maybe Grammemes) (Maybe Translations) TranslationsWordKind.WordKind


instance : TextWord -> Instance
instance (TextWord _ inst _ _ _ _) =
    inst


phrase : TextWord -> Phrase
phrase (TextWord _ _ phr _ _ _) =
    phr


word : TextWord -> TranslationsWordKind.WordKind
word (TextWord _ _ _ _ _ word_kind) =
    word_kind


wordType : TextWord -> String
wordType text_word =
    TranslationsTextWord.wordTypeToString (word text_word)


group : TextWord -> Maybe TextGroupDetails
group (TextWord _ _ _ _ _ w) =
    TranslationsTextWord.wordKindToGroup w


grammemes : TextWord -> Maybe Grammemes
grammemes (TextWord _ _ _ grams _ _) =
    grams


grammemesToString : TextWord -> String
grammemesToString text_word =
    case grammemes text_word of
        Just grs ->
            String.join ", " <|
                List.map (\( g, v ) -> g ++ ": " ++ v) <|
                    Dict.toList grs

        Nothing ->
            ""


hasTranslations : TextWord -> Bool
hasTranslations text_word =
    case translations text_word of
        Just trs ->
            True

        Nothing ->
            False


translations : TextWord -> Maybe Translations
translations (TextWord _ _ _ _ trans _) =
    trans


new : Int -> Instance -> Phrase -> Maybe Grammemes -> Maybe Translations -> TranslationsWordKind.WordKind -> TextWord
new id inst phr grams trans w =
    TextWord id inst phr grams trans w


newGrammemeFromList : Maybe (List ( String, String )) -> Grammemes
newGrammemeFromList grams =
    case grams of
        Just grs ->
            Dict.fromList grs

        Nothing ->
            Dict.empty


newFromParams : TextWordParams -> TextWord
newFromParams params =
    TextWord
        params.id
        params.instance
        params.phrase
        (Just (newGrammemeFromList params.grammemes))
        params.translations
        (TranslationsTextWord.strToWordType params.word)
