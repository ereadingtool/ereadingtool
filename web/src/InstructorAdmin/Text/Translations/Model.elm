module InstructorAdmin.Text.Translations.Model exposing
    ( Model
    , addTextTranslation
    , addToMergeWords
    , clearMerge
    , completeMerge
    , editWord
    , editingGrammemeValue
    , editingWord
    , editingWordInstance
    , getNewTranslationForWord
    , getTextWords
    , init
    , inputGrammeme
    , instanceCount
    , isMergingWords
    , mergeState
    , mergingWord
    , mergingWordInstances
    , mergingWords
    , newWordInstance
    , refreshTextWordForWordInstance
    , removeFromMergeWords
    , removeTextTranslation
    , selectGrammemeForEditing
    , setGlobalEditLock
    , setTextWord
    , setTextWords
    , uneditWord
    , updateTextTranslation
    , updateTranslationsForWord
    )

import Array exposing (Array)
import Dict exposing (Dict)
import InstructorAdmin.Text.Translations as Translations
import InstructorAdmin.Text.Translations.TextWord as TranslationsTextWord
import InstructorAdmin.Text.Translations.Word.Instance as TranslationsWordInstance
import OrderedDict exposing (OrderedDict)
import Text.Model


type alias Grammemes =
    Dict String (Maybe String)


type alias Model =
    { -- from the server, a dictionary of TextWords indexed by section number
      words : Array (Dict Translations.Word (Array TranslationsTextWord.TextWord))
    , merging_words : OrderedDict String TranslationsWordInstance.WordInstance
    , editing_grammeme : Maybe String
    , editing_grammemes : Dict String String
    , editing_words : Dict Translations.Word Int
    , editing_word_instances : Dict Translations.Word Bool
    , edit_lock : Bool
    , text : Text.Model.Text
    , text_id : Int
    , new_translations : Dict String String
    , add_as_text_word_endpoint : Translations.AddTextWordEndpoint
    , merge_textword_endpoint : Translations.MergeTextWordEndpoint
    , text_translation_match_endpoint : Translations.TextTranslationMatchEndpoint
    , flags : Translations.Flags
    }


init : Translations.Flags -> Int -> Text.Model.Text -> Model
init flags text_id text =
    { words = Array.empty
    , merging_words = OrderedDict.empty
    , editing_words = Dict.empty
    , editing_grammeme = Nothing
    , editing_grammemes = Dict.empty
    , editing_word_instances = Dict.empty
    , edit_lock = False
    , text = text
    , text_id = text_id
    , new_translations = Dict.empty
    , flags = flags
    , add_as_text_word_endpoint = Translations.AddTextWordEndpoint (Translations.URL flags.add_as_text_word_endpoint_url)
    , merge_textword_endpoint = Translations.MergeTextWordEndpoint (Translations.URL flags.merge_textword_endpoint_url)
    , text_translation_match_endpoint =
        Translations.TextTranslationMatchEndpoint (Translations.URL flags.text_translation_match_endpoint)
    }


clearEditingFields : Model -> Model
clearEditingFields model =
    { model | editing_grammemes = Dict.empty }


selectGrammemeForEditing : Model -> String -> Model
selectGrammemeForEditing model grammeme_name =
    { model | editing_grammeme = Just grammeme_name }


editingGrammeme : Model -> String
editingGrammeme model =
    let
        firstGrammemeName =
            "aspect"
    in
    Maybe.withDefault firstGrammemeName model.editing_grammeme


editingGrammemeValue : Model -> TranslationsWordInstance.WordInstance -> String
editingGrammemeValue model wordInstance =
    let
        grammemeName =
            editingGrammeme model

        wordInstanceGrammemes =
            Maybe.withDefault "" (TranslationsWordInstance.grammemeValue wordInstance grammemeName)
    in
    Maybe.withDefault wordInstanceGrammemes (Dict.get grammemeName model.editing_grammemes)


inputGrammeme : Model -> String -> Model
inputGrammeme model newGrammemeValue =
    let
        editingGrammemeName =
            editingGrammeme model
    in
    { model
        | editing_grammemes =
            Dict.insert editingGrammemeName newGrammemeValue model.editing_grammemes
    }


textWordToWordInstance : TranslationsTextWord.TextWord -> TranslationsWordInstance.WordInstance
textWordToWordInstance textWord =
    let
        section_number =
            TranslationsTextWord.sectionNumber textWord

        phrase =
            String.toLower (TranslationsTextWord.phrase textWord)

        instance =
            TranslationsTextWord.instance textWord
    in
    TranslationsWordInstance.new section_number instance phrase (Just textWord)


refreshTextWordForWordInstance :
    Model
    -> TranslationsWordInstance.WordInstance
    -> TranslationsWordInstance.WordInstance
refreshTextWordForWordInstance model wordInstance =
    let
        sectionNumber =
            TranslationsWordInstance.sectionNumber wordInstance

        instance =
            TranslationsWordInstance.instance wordInstance

        phrase =
            TranslationsWordInstance.token wordInstance
    in
    case getTextWord model sectionNumber instance phrase of
        Just textWord ->
            TranslationsWordInstance.setTextWord wordInstance textWord

        Nothing ->
            wordInstance


newWordInstance :
    Model
    -> Translations.SectionNumber
    -> Translations.Instance
    -> Translations.Token
    -> TranslationsWordInstance.WordInstance
newWordInstance model sectionNumber instance token =
    TranslationsWordInstance.new sectionNumber instance token (getTextWord model sectionNumber instance token)


mergingWordInstances : Model -> List TranslationsWordInstance.WordInstance
mergingWordInstances model =
    OrderedDict.values (mergingWords model)


mergeSiblings :
    Model
    -> TranslationsWordInstance.WordInstance
    -> List TranslationsWordInstance.WordInstance
mergeSiblings model wordInstance =
    OrderedDict.values <| OrderedDict.remove (TranslationsWordInstance.id wordInstance) (mergingWords model)


mergeState : Model -> TranslationsWordInstance.WordInstance -> Maybe Translations.MergeState
mergeState model wordInstance =
    let
        otherMergingWords =
            mergeSiblings model wordInstance
    in
    if mergingWord model wordInstance then
        if List.length otherMergingWords >= 1 then
            Just Translations.Mergeable

        else
            Just Translations.Cancelable

    else
        Nothing


isTextWordPartOfCompoundWord : Model -> TranslationsTextWord.TextWord -> Maybe ( Int, Int, Int )
isTextWordPartOfCompoundWord model textWord =
    let
        sectionNumber =
            TranslationsTextWord.sectionNumber textWord

        instance =
            TranslationsTextWord.instance textWord

        phrase =
            TranslationsTextWord.phrase textWord
    in
    isPartOfCompoundWord model sectionNumber instance phrase


isPartOfCompoundWord : Model -> Translations.SectionNumber -> Int -> String -> Maybe ( Int, Int, Int )
isPartOfCompoundWord model section_number instance word =
    case getTextWord model section_number instance word of
        Just text_word ->
            case TranslationsTextWord.group text_word of
                Just group ->
                    Just ( TranslationsTextWord.instance text_word, group.pos, group.length )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


completeMerge :
    Model
    -> Translations.SectionNumber
    -> Translations.Phrase
    -> Translations.Instance
    -> List TranslationsTextWord.TextWord
    -> Model
completeMerge model sectionNumber phrase instance textWords =
    let
        newModel =
            setTextWords model textWords
                |> clearMerge
                |> uneditAllWords

        mergedWordInstance =
            newWordInstance newModel sectionNumber instance phrase
    in
    editWord newModel mergedWordInstance


clearMerge : Model -> Model
clearMerge model =
    { model | merging_words = OrderedDict.empty }


isMergingWords : Model -> Bool
isMergingWords model =
    not (OrderedDict.isEmpty model.merging_words)


mergingWords : Model -> OrderedDict String TranslationsWordInstance.WordInstance
mergingWords model =
    model.merging_words


mergingWord : Model -> TranslationsWordInstance.WordInstance -> Bool
mergingWord model wordInstance =
    OrderedDict.member (TranslationsWordInstance.id wordInstance) model.merging_words


addToMergeWords : Model -> TranslationsWordInstance.WordInstance -> Model
addToMergeWords model wordInstance =
    { model
        | merging_words =
            OrderedDict.insert (TranslationsWordInstance.id wordInstance) wordInstance model.merging_words
    }


removeFromMergeWords : Model -> TranslationsWordInstance.WordInstance -> Model
removeFromMergeWords model wordInstance =
    { model
        | merging_words =
            OrderedDict.remove (TranslationsWordInstance.id wordInstance) model.merging_words
    }


instanceCount : Model -> Translations.SectionNumber -> Translations.Word -> Int
instanceCount model sectionNumber word =
    case getTextWords model sectionNumber (String.toLower word) of
        Just textWords ->
            Array.length textWords

        Nothing ->
            0


getTextWords :
    Model
    -> Translations.SectionNumber
    -> Translations.Phrase
    -> Maybe (Array TranslationsTextWord.TextWord)
getTextWords model sectionNumber phrase =
    getSectionWords model sectionNumber
        |> Maybe.andThen (Dict.get (String.toLower phrase))


editingWord : Model -> String -> Bool
editingWord model word =
    Dict.member (String.toLower word) model.editing_words


wordInstanceKey : TranslationsWordInstance.WordInstance -> String
wordInstanceKey wordInstance =
    TranslationsWordInstance.id wordInstance


setGlobalEditLock : Model -> Bool -> Model
setGlobalEditLock model value =
    { model | edit_lock = value }


editWord : Model -> TranslationsWordInstance.WordInstance -> Model
editWord model wordInstance =
    let
        normalizedWord =
            String.toLower (TranslationsWordInstance.word wordInstance)

        newEditedWords =
            case Dict.get normalizedWord model.editing_words of
                Just refCount ->
                    Dict.insert normalizedWord (refCount + 1) model.editing_words

                Nothing ->
                    Dict.insert normalizedWord 0 model.editing_words

        newEditingWordInstances =
            Dict.insert (wordInstanceKey wordInstance) True model.editing_word_instances
    in
    { model | editing_words = newEditedWords, editing_word_instances = newEditingWordInstances }


uneditAllWords : Model -> Model
uneditAllWords model =
    { model
        | editing_words = Dict.empty
        , editing_word_instances = Dict.empty
    }


uneditWord : Model -> TranslationsWordInstance.WordInstance -> Model
uneditWord model wordInstance =
    let
        word =
            TranslationsWordInstance.word wordInstance

        normalizedWord =
            String.toLower word

        newEditedWords =
            case Dict.get normalizedWord model.editing_words of
                Just refCount ->
                    if (refCount - 1) == -1 then
                        Dict.remove normalizedWord model.editing_words

                    else
                        Dict.insert normalizedWord (refCount - 1) model.editing_words

                Nothing ->
                    model.editing_words

        newEditingWordInstances =
            Dict.remove (wordInstanceKey wordInstance) model.editing_word_instances

        cancelled_merge_model =
            clearMerge model
    in
    { cancelled_merge_model
        | editing_words = newEditedWords
        , editing_word_instances = newEditingWordInstances
        , editing_grammemes = Dict.empty
    }


editingWordInstance : Model -> TranslationsWordInstance.WordInstance -> Bool
editingWordInstance model wordInstance =
    Dict.member (TranslationsWordInstance.id wordInstance) model.editing_word_instances


getTextWord :
    Model
    -> Translations.SectionNumber
    -> Int
    -> Translations.Phrase
    -> Maybe TranslationsTextWord.TextWord
getTextWord model sectionNumber instance phrase =
    getTextWords model sectionNumber (String.toLower phrase)
        |> Maybe.andThen (Array.get instance)


setTextWords : Model -> List TranslationsTextWord.TextWord -> Model
setTextWords model textWords =
    let
        -- ensure we're initializing the arrays in the right order
        sortedTextWords =
            List.sortBy (\textWord -> TranslationsTextWord.instance textWord) textWords

        newModel =
            clearEditingFields model
    in
    List.foldl (\textWord accModel -> setTextWord accModel textWord) newModel sortedTextWords


getSectionWords :
    Model
    -> Translations.SectionNumber
    -> Maybe (Dict Translations.Word (Array TranslationsTextWord.TextWord))
getSectionWords model sectionNumber =
    Array.get (Translations.sectionNumberToInt sectionNumber) model.words


setSectionWords :
    Model
    -> Translations.SectionNumber
    -> Dict Translations.Word (Array TranslationsTextWord.TextWord)
    -> Model
setSectionWords model sectionNumber words =
    { model | words = Array.set (Translations.sectionNumberToInt sectionNumber) words model.words }


setTextWordsForPhrase :
    Model
    -> Translations.SectionNumber
    -> Translations.Phrase
    -> Array TranslationsTextWord.TextWord
    -> Model
setTextWordsForPhrase model sectionNumber phrase textWords =
    case getSectionWords model sectionNumber of
        Just sectionWords ->
            setSectionWords model sectionNumber (Dict.insert (String.toLower phrase) textWords sectionWords)

        Nothing ->
            model


setTextWord : Model -> TranslationsTextWord.TextWord -> Model
setTextWord model textWord =
    let
        sectionNumber =
            TranslationsTextWord.sectionNumber textWord

        phrase =
            TranslationsTextWord.phrase textWord

        instance =
            TranslationsTextWord.instance textWord

        newTextWords =
            case getTextWords model sectionNumber phrase of
                Just textWords ->
                    Array.set instance textWord textWords

                -- word not found
                Nothing ->
                    Array.fromList [ textWord ]
    in
    setTextWordsForPhrase model sectionNumber phrase newTextWords


updateTextTranslation : Model -> TranslationsTextWord.TextWord -> Translations.Translation -> Model
updateTextTranslation model textWord translation =
    let
        newTextWord =
            TranslationsTextWord.updateTranslation
                (TranslationsTextWord.setNoTRCorrectForContext textWord)
                translation
    in
    setTextWord model newTextWord


getNewTranslationForWord : Model -> TranslationsTextWord.TextWord -> Maybe String
getNewTranslationForWord model textWord =
    Dict.get (TranslationsTextWord.phrase textWord) model.new_translations


updateTranslationsForWord : Model -> TranslationsTextWord.TextWord -> String -> Model
updateTranslationsForWord model textWord translationText =
    let
        phrase =
            TranslationsTextWord.phrase textWord
    in
    { model | new_translations = Dict.insert phrase translationText model.new_translations }


addTextTranslation : Model -> TranslationsTextWord.TextWord -> Translations.Translation -> Model
addTextTranslation model newTextWord _ =
    setTextWord model newTextWord


removeTextTranslation : Model -> TranslationsTextWord.TextWord -> Translations.Translation -> Model
removeTextTranslation model textWord translation =
    let
        newTextWord =
            TranslationsTextWord.removeTranslation textWord translation
    in
    setTextWord model newTextWord
