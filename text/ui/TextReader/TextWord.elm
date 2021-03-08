module TextReader.TextWord exposing (..)

import Dict exposing (Dict)
import Text.Translations exposing (..)
import Text.Translations.TextWord
import Text.Translations.Word.Kind


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
    = TextWord Int Instance Phrase (Maybe Grammemes) (Maybe Translations) Text.Translations.Word.Kind.WordKind


instance : TextWord -> Instance
instance (TextWord _ inst _ _ _ _) =
    inst


phrase : TextWord -> Phrase
phrase (TextWord _ _ phr _ _ _) =
    phr


word : TextWord -> Text.Translations.Word.Kind.WordKind
word (TextWord _ _ _ _ _ word_kind) =
    word_kind


wordType : TextWord -> String
wordType text_word =
    Text.Translations.TextWord.wordTypeToString (word text_word)


group : TextWord -> Maybe TextGroupDetails
group (TextWord _ _ _ _ _ w) =
    Text.Translations.TextWord.wordKindToGroup w


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


new : Int -> Instance -> Phrase -> Maybe Grammemes -> Maybe Translations -> Text.Translations.Word.Kind.WordKind -> TextWord
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
        (Text.Translations.TextWord.strToWordType params.word)
