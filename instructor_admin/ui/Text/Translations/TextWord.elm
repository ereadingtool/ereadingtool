module Text.Translations.TextWord exposing
    ( Endpoints
    , TextWord
    , grammemeValue
    , grammemes
    , group
    , idToInt
    , instance
    , new
    , phrase
    , removeTranslation
    , sectionNumber
    , setNoTRCorrectForContext
    , strToWordType
    , textWordEndpoint
    , translations
    , updateTranslation
    , wordKindToGroup
    , wordType
    , wordTypeToString
    )

import Dict
import Text.Translations exposing (..)
import Text.Translations.Word.Kind exposing (WordKind(..))


type alias Endpoints =
    { text_word : String
    , translations : String
    }


type TextWord
    = TextWord TextWordId SectionNumber Instance Phrase (Maybe Grammemes) (Maybe Translations) WordKind Endpoints


grammemeValue : TextWord -> String -> Maybe String
grammemeValue textWord grammemeName =
    grammemes textWord
        |> Maybe.andThen (Dict.get grammemeName)


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


translationsEndpoint : TextWord -> String
translationsEndpoint textWord =
    (endpoints textWord).translations


textWordEndpoint : TextWord -> String
textWordEndpoint textWord =
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
new wordId section inst phr maybeGrammemes maybeTranslations word endpnts =
    TextWord wordId section inst phr maybeGrammemes maybeTranslations word endpnts


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
            translations textWord
                |> Maybe.map (List.map (\tr -> { tr | correct_for_context = False }))
                |> Maybe.map (\trs -> trs ++ [ translation ])
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
