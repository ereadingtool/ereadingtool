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
textWordToString textWord =
    "("
        ++ String.join " "
            [ toString (id textWord)
            , toString (sectionNumber textWord)
            , toString (instance textWord)
            , toString (phrase textWord)
            , toString (wordKindToGroup (wordKind textWord))
            ]
        ++ ")"


textWordEndpoint : TextWord -> String
textWordEndpoint textWord =
    (endpoints textWord).text_word


grammemeValue : TextWord -> String -> Maybe String
grammemeValue textWord grammemeName =
    case grammemes textWord of
        Just grammes ->
            Dict.get grammemeName grammes

        Nothing ->
            Nothing


grammemes : TextWord -> Maybe Grammemes
grammemes (TextWord _ _ _ _ maybeGrammemes _ _ _) =
    maybeGrammemes


strToWordType : ( String, Maybe TextGroupDetails ) -> WordKind
strToWordType ( str, groupDetails ) =
    case str of
        "single" ->
            SingleWord groupDetails

        "compound" ->
            CompoundWord

        _ ->
            SingleWord groupDetails


wordTypeToString : WordKind -> String
wordTypeToString word =
    case word of
        SingleWord _ ->
            "single"

        CompoundWord ->
            "compound"


wordType : TextWord -> String
wordType textWord =
    wordTypeToString (wordKind textWord)


sectionNumber : TextWord -> SectionNumber
sectionNumber (TextWord _ section _ _ _ _ _ _) =
    section


wordKind : TextWord -> WordKind
wordKind (TextWord _ _ _ _ _ _ wk _) =
    wk


instance : TextWord -> Int
instance (TextWord _ _ inst _ _ _ _ _) =
    inst


wordKindToGroup : WordKind -> Maybe TextGroupDetails
wordKindToGroup word =
    case word of
        SingleWord groupDetails ->
            groupDetails

        CompoundWord ->
            Nothing


group : TextWord -> Maybe TextGroupDetails
group (TextWord _ _ _ _ _ _ word _) =
    wordKindToGroup word


endpoints : TextWord -> Endpoints
endpoints (TextWord _ _ _ _ _ _ _ endpnts) =
    endpnts


translations_endpoint : TextWord -> String
translations_endpoint textWord =
    (endpoints textWord).translations


text_word_endpoint : TextWord -> String
text_word_endpoint textWord =
    (endpoints textWord).text_word


id : TextWord -> TextWordId
id (TextWord wordId _ _ _ _ _ _ _) =
    wordId


idToInt : TextWord -> Int
idToInt textWord =
    textWordIdToInt (id textWord)


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
setTranslations (TextWord wordId section inst phrs maybeGrammemes _ word endpnts) newTranslations =
    TextWord wordId section inst phrs maybeGrammemes newTranslations word endpnts


addTranslation : TextWord -> Translation -> TextWord
addTranslation textWord translation =
    let
        newTranslations =
            case translations textWord of
                Just trs ->
                    Just (List.map (\tr -> { tr | correct_for_context = False }) trs ++ [ translation ])

                Nothing ->
                    Nothing
    in
    setTranslations textWord newTranslations


removeTranslation : TextWord -> Translation -> TextWord
removeTranslation textWord textWordTranslation =
    case translations textWord of
        Just trs ->
            let
                newTranslations =
                    List.filter (\tr -> tr.id /= textWordTranslation.id) trs
            in
            setTranslations textWord (Just newTranslations)

        -- no translations
        Nothing ->
            textWord


updateTranslation : TextWord -> Translation -> TextWord
updateTranslation textWord textWordTranslation =
    case translations textWord of
        Just trs ->
            let
                newTranslations =
                    List.map
                        (\tr ->
                            if tr.id == textWordTranslation.id then
                                textWordTranslation

                            else
                                tr
                        )
                        trs
            in
            setTranslations textWord (Just newTranslations)

        -- word has no translations
        Nothing ->
            textWord


setNoTRCorrectForContext : TextWord -> TextWord
setNoTRCorrectForContext textWord =
    case translations textWord of
        Just trs ->
            let
                newTranslations =
                    List.map (\tr -> { tr | correct_for_context = False }) trs
            in
            setTranslations textWord (Just newTranslations)

        Nothing ->
            textWord
