module Text.Translations.TextWord exposing (..)

-- grammemes, TextWord, Endpoints

import Dict exposing (Dict)
import Text.Translations exposing (..)
import Text.Translations.Word.Kind exposing (WordKind(..))


type alias Endpoints =
    { text_word : String
    , translations : String
    }


type TextWord
    = TextWord TextWordId SectionNumber Instance Phrase (Maybe Grammemes) (Maybe Translations) WordKind Endpoints


textWordToString : TextWord -> String
textWordToString text_word =
    "("
        ++ String.join " "
            [ toString (id text_word)
            , toString (sectionNumber text_word)
            , toString (instance text_word)
            , toString (phrase text_word)
            , toString (wordKindToGroup (wordKind text_word))
            ]
        ++ ")"


textWordEndpoint : TextWord -> String
textWordEndpoint text_word =
    (endpoints text_word).text_word


grammemeValue : TextWord -> String -> Maybe String
grammemeValue text_word grammeme_name =
    case grammemes text_word of
        Just grammes ->
            Dict.get grammeme_name grammes

        Nothing ->
            Nothing


grammemes : TextWord -> Maybe Grammemes
grammemes (TextWord _ _ _ _ maybeGrammemes _ _ _) =
    maybeGrammemes


strToWordType : ( String, Maybe TextGroupDetails ) -> WordKind
strToWordType ( str, group_details ) =
    case str of
        "single" ->
            SingleWord group_details

        "compound" ->
            CompoundWord

        _ ->
            SingleWord group_details


wordTypeToString : WordKind -> String
wordTypeToString word =
    case word of
        SingleWord _ ->
            "single"

        CompoundWord ->
            "compound"


wordType : TextWord -> String
wordType text_word =
    wordTypeToString (wordKind text_word)


sectionNumber : TextWord -> SectionNumber
sectionNumber (TextWord _ section _ _ _ _ _ _) =
    section


wordKind : TextWord -> WordKind
wordKind (TextWord _ _ _ _ _ _ word_kind _) =
    word_kind


instance : TextWord -> Int
instance (TextWord _ _ inst _ _ _ _ _) =
    inst


wordKindToGroup : WordKind -> Maybe TextGroupDetails
wordKindToGroup word =
    case word of
        SingleWord group_details ->
            group_details

        CompoundWord ->
            Nothing


group : TextWord -> Maybe TextGroupDetails
group (TextWord _ _ _ _ _ _ word _) =
    wordKindToGroup word


endpoints : TextWord -> Endpoints
endpoints (TextWord _ _ _ _ _ _ _ endpnts) =
    endpnts


translations_endpoint : TextWord -> String
translations_endpoint text_word =
    (endpoints text_word).translations


text_word_endpoint : TextWord -> String
text_word_endpoint text_word =
    (endpoints text_word).text_word


id : TextWord -> TextWordId
id (TextWord wordId _ _ _ _ _ _ _) =
    wordId


idToInt : TextWord -> Int
idToInt text_word =
    textWordIdToInt (id text_word)


new :
    TextWordId
    -> SectionNumber
    -> Instance
    -> Phrase
    -> Maybe Grammemes
    -> Maybe Translations
    -> WordKind
    -> Endpoints
    -> TextWord
new wordId section inst phrs maybeGrammemes maybeTranslations word endpnts =
    TextWord wordId section inst phrase maybeGrammemes maybeTranslations word endpnts


phrase : TextWord -> Phrase
phrase (TextWord _ _ _ phrs _ _ _ _) =
    phrs


translations : TextWord -> Maybe Translations
translations (TextWord _ _ _ _ _ maybeTranslations _ _) =
    maybeTranslations


setTranslations : TextWord -> Maybe Translations -> TextWord
setTranslations (TextWord wordId section inst phrs maybeGrammemes _ word endpnts) new_translations =
    TextWord wordId section inst phrs maybeGrammemes new_translations word endpnts


addTranslation : TextWord -> Translation -> TextWord
addTranslation text_word translation =
    let
        new_translations =
            case translations text_word of
                Just trs ->
                    Just (List.map (\tr -> { tr | correct_for_context = False }) trs ++ [ translation ])

                Nothing ->
                    Nothing
    in
    setTranslations text_word new_translations


removeTranslation : TextWord -> Translation -> TextWord
removeTranslation text_word text_word_translation =
    case translations text_word of
        Just trs ->
            let
                new_translations =
                    List.filter (\tr -> tr.id /= text_word_translation.id) trs
            in
            setTranslations text_word (Just new_translations)

        -- no translations
        Nothing ->
            text_word


updateTranslation : TextWord -> Translation -> TextWord
updateTranslation text_word text_word_translation =
    case translations text_word of
        Just trs ->
            let
                new_translations =
                    List.map
                        (\tr ->
                            if tr.id == text_word_translation.id then
                                text_word_translation

                            else
                                tr
                        )
                        trs
            in
            setTranslations text_word (Just new_translations)

        -- word has no translations
        Nothing ->
            text_word


setNoTRCorrectForContext : TextWord -> TextWord
setNoTRCorrectForContext text_word =
    case translations text_word of
        Just trs ->
            let
                new_translations =
                    List.map (\tr -> { tr | correct_for_context = False }) trs
            in
            setTranslations text_word (Just new_translations)

        Nothing ->
            text_word
