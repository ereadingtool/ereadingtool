module Text.Translations.Model exposing
    ( Model
    , TextTranslations
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
    , setTextWord
    , setTextWords
    , uneditWord
    , updateTextTranslation
    , updateTranslationsForWord
    )

import Array exposing (Array)
import Dict exposing (Dict)
import OrderedDict exposing (OrderedDict)
import Text.Model
import Text.Translations exposing (..)
import Text.Translations.TextWord exposing (TextWord)
import Text.Translations.Word.Instance exposing (WordInstance)


type alias Grammemes =
    Dict String (Maybe String)


type alias Model =
    { -- from the server, a dictionary of TextWords indexed by section number
      words : Array (Dict Text.Translations.Word (Array TextWord))
    , merging_words : OrderedDict String WordInstance
    , editing_grammeme : Maybe String
    , editing_grammemes : Dict String String
    , editing_words : Dict Text.Translations.Word Int
    , editing_word_instances : Dict Text.Translations.Word Bool
    , edit_lock : Bool
    , text : Text.Model.Text
    , text_id : Int
    , new_translations : Dict String String
    , add_as_text_word_endpoint : Text.Translations.AddTextWordEndpoint
    , merge_textword_endpoint : Text.Translations.MergeTextWordEndpoint
    , text_translation_match_endpoint : Text.Translations.TextTranslationMatchEndpoint
    , flags : Flags
    }


init : Flags -> Int -> Text.Model.Text -> Model
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
    , add_as_text_word_endpoint = AddTextWordEndpoint (URL flags.add_as_text_word_endpoint_url)
    , merge_textword_endpoint = MergeTextWordEndpoint (URL flags.merge_textword_endpoint_url)
    , text_translation_match_endpoint =
        Text.Translations.TextTranslationMatchEndpoint (URL flags.text_translation_match_endpoint)
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


editingGrammemeValue : Model -> WordInstance -> String
editingGrammemeValue model wordInstance =
    let
        grammemeName =
            editingGrammeme model

        wordInstanceGrammemes =
            Maybe.withDefault "" (Text.Translations.Word.Instance.grammemeValue wordInstance grammemeName)
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


textWordToWordInstance : TextWord -> WordInstance
textWordToWordInstance textWord =
    let
        section_number =
            Text.Translations.TextWord.sectionNumber textWord

        phrase =
            String.toLower (Text.Translations.TextWord.phrase textWord)

        instance =
            Text.Translations.TextWord.instance textWord
    in
    Text.Translations.Word.Instance.new section_number instance phrase (Just textWord)


refreshTextWordForWordInstance : Model -> WordInstance -> WordInstance
refreshTextWordForWordInstance model wordInstance =
    let
        sectionNumber =
            Text.Translations.Word.Instance.sectionNumber wordInstance

        instance =
            Text.Translations.Word.Instance.instance wordInstance

        phrase =
            Text.Translations.Word.Instance.token wordInstance
    in
    case getTextWord model sectionNumber instance phrase of
        Just textWord ->
            Text.Translations.Word.Instance.setTextWord wordInstance textWord

        Nothing ->
            wordInstance


newWordInstance : Model -> SectionNumber -> Instance -> Token -> WordInstance
newWordInstance model sectionNumber instance token =
    Text.Translations.Word.Instance.new sectionNumber instance token (getTextWord model sectionNumber instance token)


mergingWordInstances : Model -> List WordInstance
mergingWordInstances model =
    OrderedDict.values (mergingWords model)


mergeSiblings : Model -> WordInstance -> List WordInstance
mergeSiblings model wordInstance =
    OrderedDict.values <| OrderedDict.remove (Text.Translations.Word.Instance.id wordInstance) (mergingWords model)


mergeState : Model -> WordInstance -> Maybe MergeState
mergeState model wordInstance =
    let
        otherMergingWords =
            mergeSiblings model wordInstance
    in
    if mergingWord model wordInstance then
        if List.length otherMergingWords >= 1 then
            Just Mergeable

        else
            Just Cancelable

    else
        Nothing


isTextWordPartOfCompoundWord : Model -> TextWord -> Maybe ( Int, Int, Int )
isTextWordPartOfCompoundWord model textWord =
    let
        sectionNumber =
            Text.Translations.TextWord.sectionNumber textWord

        instance =
            Text.Translations.TextWord.instance textWord

        phrase =
            Text.Translations.TextWord.phrase textWord
    in
    isPartOfCompoundWord model sectionNumber instance phrase


isPartOfCompoundWord : Model -> SectionNumber -> Int -> String -> Maybe ( Int, Int, Int )
isPartOfCompoundWord model section_number instance word =
    case getTextWord model section_number instance word of
        Just text_word ->
            case Text.Translations.TextWord.group text_word of
                Just group ->
                    Just ( Text.Translations.TextWord.instance text_word, group.pos, group.length )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


completeMerge : Model -> SectionNumber -> Phrase -> Instance -> List TextWord -> Model
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


mergingWords : Model -> OrderedDict String WordInstance
mergingWords model =
    model.merging_words


mergingWord : Model -> WordInstance -> Bool
mergingWord model wordInstance =
    OrderedDict.member (Text.Translations.Word.Instance.id wordInstance) model.merging_words


addToMergeWords : Model -> WordInstance -> Model
addToMergeWords model wordInstance =
    { model
        | merging_words =
            OrderedDict.insert (Text.Translations.Word.Instance.id wordInstance) wordInstance model.merging_words
    }


removeFromMergeWords : Model -> WordInstance -> Model
removeFromMergeWords model wordInstance =
    { model
        | merging_words =
            OrderedDict.remove (Text.Translations.Word.Instance.id wordInstance) model.merging_words
    }


instanceCount : Model -> SectionNumber -> Text.Translations.Word -> Int
instanceCount model sectionNumber word =
    case getTextWords model sectionNumber (String.toLower word) of
        Just textWords ->
            Array.length textWords

        Nothing ->
            0


getTextWords : Model -> SectionNumber -> Phrase -> Maybe (Array TextWord)
getTextWords model sectionNumber phrase =
    getSectionWords model sectionNumber
        |> Maybe.andThen (Dict.get (String.toLower phrase))


editingWord : Model -> String -> Bool
editingWord model word =
    Dict.member (String.toLower word) model.editing_words


wordInstanceKey : WordInstance -> String
wordInstanceKey wordInstance =
    Text.Translations.Word.Instance.id wordInstance


setGlobalEditLock : Model -> Bool -> Model
setGlobalEditLock model value =
    { model | edit_lock = value }


editWord : Model -> WordInstance -> Model
editWord model wordInstance =
    let
        normalizedWord =
            String.toLower (Text.Translations.Word.Instance.word wordInstance)

        newEditedWords =
            case Dict.get normalizedWord model.editing_words of
                Just refCount ->
                    Dict.insert normalizedWord (refCount + 1) model.editing_words

                Nothing ->
                    Dict.insert normalized_word 0 model.editing_words

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


uneditWord : Model -> WordInstance -> Model
uneditWord model wordInstance =
    let
        word =
            Text.Translations.Word.Instance.word wordInstance

        normalizedWord =
            String.toLower word

        newEditedWords =
            case Dict.get normalizedWord model.editingWords of
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


editingWordInstance : Model -> WordInstance -> Bool
editingWordInstance model wordInstance =
    Dict.member (Text.Translations.Word.Instance.id wordInstance) model.editing_word_instances


getTextWord : Model -> SectionNumber -> Int -> Phrase -> Maybe TextWord
getTextWord model sectionNumber instance phrase =
    getTextWords model sectionNumber (String.toLower phrase)
        |> Maybe.andThen (Array.get instance)


setTextWords : Model -> List TextWord -> Model
setTextWords model textWords =
    let
        -- ensure we're initializing the arrays in the right order
        sortedTextWords =
            List.sortBy (\textWord -> Text.Translations.TextWord.instance textWord) textWords

        newModel =
            clearEditingFields model
    in
    List.foldl (\textWord model -> setTextWord model textWord) newModel sortedTextWords


getSectionWords : Model -> SectionNumber -> Maybe (Dict Text.Translations.Word (Array TextWord))
getSectionWords model sectionNumber =
    Array.get (sectionNumberToInt sectionNumber) model.words


setSectionWords : Model -> SectionNumber -> Dict Text.Translations.Word (Array TextWord) -> Model
setSectionWords model sectionNumber words =
    { model | words = Array.set (sectionNumberToInt sectionNumber) words model.words }


setTextWordsForPhrase : Model -> SectionNumber -> Phrase -> Array TextWord -> Model
setTextWordsForPhrase model sectionNumber phrase textWords =
    case getSectionWords model sectionNumber of
        Just sectionWords ->
            setSectionWords model sectionNumber (Dict.insert (String.toLower phrase) textWords sectionWords)

        Nothing ->
            model


setTextWord : Model -> TextWord -> Model
setTextWord model textWord =
    let
        sectionNumber =
            Text.Translations.TextWord.sectionNumber textWord

        phrase =
            Text.Translations.TextWord.phrase textWord

        instance =
            Text.Translations.TextWord.instance textWord

        newTextWords =
            case getTextWords model sectionNumber phrase of
                Just textWords ->
                    Array.set instance textWord textWords

                -- word not found
                Nothing ->
                    Array.fromList [ textWord ]
    in
    setTextWordsForPhrase model sectionNumber phrase newTextWords


updateTextTranslation : Model -> Text.Translations.TextWord.TextWord -> Translation -> Model
updateTextTranslation model textWord translation =
    let
        newTextWord =
            Text.Translations.TextWord.updateTranslation
                (Text.Translations.TextWord.setNoTRCorrectForContext textWord)
                translation
    in
    setTextWord model newTextWord


getNewTranslationForWord : Model -> TextWord -> Maybe String
getNewTranslationForWord model textWord =
    Dict.get (Text.Translations.TextWord.phrase textWord) model.new_translations


updateTranslationsForWord : Model -> TextWord -> String -> Model
updateTranslationsForWord model textWord translationText =
    let
        phrase =
            Text.Translations.TextWord.phrase textWord
    in
    { model | new_translations = Dict.insert phrase translationText model.new_translations }


addTextTranslation : Model -> TextWord -> Translation -> Model
addTextTranslation model newTextWord _ =
    setTextWord model newTextWord


removeTextTranslation : Model -> TextWord -> Translation -> Model
removeTextTranslation model textWord translation =
    let
        newTextWord =
            Text.Translations.TextWord.removeTranslation textWord translation
    in
    setTextWord model newTextWord
