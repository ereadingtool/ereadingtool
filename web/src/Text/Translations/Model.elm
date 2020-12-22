module Text.Translations.Model exposing
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
    , inCompoundWord
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
    , wordInstanceKey
    )

import Api.Config exposing (Config)
import Array exposing (Array)
import Dict exposing (Dict)
import OrderedDict exposing (OrderedDict)
import Session exposing (Session)
import Text.Model
import Text.Translations
import Text.Translations.TextWord
import Text.Translations.Word.Instance


type alias Grammemes =
    Dict String (Maybe String)


type alias Model =
    { -- from the server, a dictionary of TextWords indexed by section number
      session : Session
    , config : Config
    , words : Array (Dict Text.Translations.Word (Array Text.Translations.TextWord.TextWord))
    , merging_words : OrderedDict String Text.Translations.Word.Instance.WordInstance
    , editing_grammeme : Maybe String
    , editing_grammemes : Dict String String
    , editing_words : Dict Text.Translations.Word Int
    , editing_word_instances : Dict Text.Translations.Word Bool
    , edit_lock : Bool
    , text : Text.Model.Text
    , text_id : Int
    , new_translations : Dict String String
    }


init : Text.Translations.Flags -> Int -> Text.Model.Text -> Model
init flags text_id text =
    { session = flags.session
    , config = flags.config
    , words = Array.empty
    , merging_words = OrderedDict.empty
    , editing_words = Dict.empty
    , editing_grammeme = Nothing
    , editing_grammemes = Dict.empty
    , editing_word_instances = Dict.empty
    , edit_lock = False
    , text = text
    , text_id = text_id
    , new_translations = Dict.empty
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
            "lemma"
    in
    Maybe.withDefault firstGrammemeName model.editing_grammeme


editingGrammemeValue : Model -> Text.Translations.Word.Instance.WordInstance -> String
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


textWordToWordInstance : Text.Translations.TextWord.TextWord -> Text.Translations.Word.Instance.WordInstance
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


refreshTextWordForWordInstance :
    Model
    -> Text.Translations.Word.Instance.WordInstance
    -> Text.Translations.Word.Instance.WordInstance
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


newWordInstance :
    Model
    -> Text.Translations.SectionNumber
    -> Text.Translations.Instance
    -> Text.Translations.Token
    -> Text.Translations.Word.Instance.WordInstance
newWordInstance model sectionNumber instance token =
    Text.Translations.Word.Instance.new sectionNumber instance token (getTextWord model sectionNumber instance token)


mergingWordInstances : Model -> List Text.Translations.Word.Instance.WordInstance
mergingWordInstances model =
    OrderedDict.values (mergingWords model)


mergeSiblings :
    Model
    -> Text.Translations.Word.Instance.WordInstance
    -> List Text.Translations.Word.Instance.WordInstance
mergeSiblings model wordInstance =
    OrderedDict.values <| OrderedDict.remove (Text.Translations.Word.Instance.id wordInstance) (mergingWords model)


mergeState : Model -> Text.Translations.Word.Instance.WordInstance -> Maybe Text.Translations.MergeState
mergeState model wordInstance =
    let
        otherMergingWords =
            mergeSiblings model wordInstance
    in
    if mergingWord model wordInstance then
        if List.length otherMergingWords >= 1 then
            Just Text.Translations.Mergeable

        else
            Just Text.Translations.Cancelable

    else
        Nothing



-- isTextWordPartOfCompoundWord : Model -> Text.Translations.TextWord.TextWord -> Maybe ( Int, Int, Int )
-- isTextWordPartOfCompoundWord model textWord =
--     let
--         sectionNumber =
--             Text.Translations.TextWord.sectionNumber textWord
--         instance =
--             Text.Translations.TextWord.instance textWord
--         phrase =
--             Text.Translations.TextWord.phrase textWord
--     in
--     isPartOfCompoundWord model sectionNumber instance phrase


inCompoundWord : Model -> Text.Translations.SectionNumber -> Int -> String -> Maybe ( Int, Int, Int )
inCompoundWord model section_number instance word =
    case getTextWord model section_number instance word of
        Just text_word ->
            case Text.Translations.TextWord.group text_word of
                Just group ->
                    -- Just ( Text.Translations.TextWord.instance text_word, group.pos, group.length )
                    Just ( group.id, group.pos, group.length )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


completeMerge :
    Model
    -> Text.Translations.SectionNumber
    -> Text.Translations.Phrase
    -> Text.Translations.Instance
    -> List Text.Translations.TextWord.TextWord
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


mergingWords : Model -> OrderedDict String Text.Translations.Word.Instance.WordInstance
mergingWords model =
    model.merging_words


mergingWord : Model -> Text.Translations.Word.Instance.WordInstance -> Bool
mergingWord model wordInstance =
    OrderedDict.member (Text.Translations.Word.Instance.id wordInstance) model.merging_words


addToMergeWords : Model -> Text.Translations.Word.Instance.WordInstance -> Model
addToMergeWords model wordInstance =
    { model
        | merging_words =
            OrderedDict.insert (Text.Translations.Word.Instance.id wordInstance) wordInstance model.merging_words
    }


removeFromMergeWords : Model -> Text.Translations.Word.Instance.WordInstance -> Model
removeFromMergeWords model wordInstance =
    { model
        | merging_words =
            OrderedDict.remove (Text.Translations.Word.Instance.id wordInstance) model.merging_words
    }


instanceCount : Model -> Text.Translations.SectionNumber -> Text.Translations.Word -> Int
instanceCount model sectionNumber word =
    case getTextWords model sectionNumber (String.toLower word) of
        Just textWords ->
            Array.length textWords

        Nothing ->
            0


getTextWords :
    Model
    -> Text.Translations.SectionNumber
    -> Text.Translations.Phrase
    -> Maybe (Array Text.Translations.TextWord.TextWord)
getTextWords model sectionNumber phrase =
    getSectionWords model sectionNumber
        |> Maybe.andThen (Dict.get (String.toLower phrase))


editingWord : Model -> String -> Bool
editingWord model word =
    Dict.member (String.toLower word) model.editing_words


wordInstanceKey : Text.Translations.Word.Instance.WordInstance -> String
wordInstanceKey wordInstance =
    Text.Translations.Word.Instance.id wordInstance


setGlobalEditLock : Model -> Bool -> Model
setGlobalEditLock model value =
    { model | edit_lock = value }


editWord : Model -> Text.Translations.Word.Instance.WordInstance -> Model
editWord model wordInstance =
    let
        normalizedWord =
            String.toLower (Text.Translations.Word.Instance.word wordInstance)

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


uneditWord : Model -> Text.Translations.Word.Instance.WordInstance -> Model
uneditWord model wordInstance =
    let
        word =
            Text.Translations.Word.Instance.word wordInstance

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


editingWordInstance : Model -> Text.Translations.Word.Instance.WordInstance -> Bool
editingWordInstance model wordInstance =
    Dict.member (Text.Translations.Word.Instance.id wordInstance) model.editing_word_instances


getTextWord :
    Model
    -> Text.Translations.SectionNumber
    -> Int
    -> Text.Translations.Phrase
    -> Maybe Text.Translations.TextWord.TextWord
getTextWord model sectionNumber instance phrase =
    getTextWords model sectionNumber (String.toLower phrase)
        |> Maybe.andThen (Array.get instance)


setTextWords : Model -> List Text.Translations.TextWord.TextWord -> Model
setTextWords model textWords =
    let
        -- ensure we're initializing the arrays in the right order
        sortedTextWords =
            List.sortBy (\textWord -> Text.Translations.TextWord.instance textWord) textWords

        newModel =
            clearEditingFields model
    in
    List.foldl (\textWord accModel -> setTextWord accModel textWord) newModel sortedTextWords


getSectionWords :
    Model
    -> Text.Translations.SectionNumber
    -> Maybe (Dict Text.Translations.Word (Array Text.Translations.TextWord.TextWord))
getSectionWords model sectionNumber =
    Array.get (Text.Translations.sectionNumberToInt sectionNumber) model.words


setSectionWords :
    Model
    -> Text.Translations.SectionNumber
    -> Dict Text.Translations.Word (Array Text.Translations.TextWord.TextWord)
    -> Model
setSectionWords model sectionNumber words =
    { model | words = Array.set (Text.Translations.sectionNumberToInt sectionNumber) words model.words }


setTextWordsForPhrase :
    Model
    -> Text.Translations.SectionNumber
    -> Text.Translations.Phrase
    -> Array Text.Translations.TextWord.TextWord
    -> Model
setTextWordsForPhrase model sectionNumber phrase textWords =
    case getSectionWords model sectionNumber of
        Just sectionWords ->
            setSectionWords model sectionNumber (Dict.insert (String.toLower phrase) textWords sectionWords)

        Nothing ->
            model


setTextWord : Model -> Text.Translations.TextWord.TextWord -> Model
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


updateTextTranslation : Model -> Text.Translations.TextWord.TextWord -> Text.Translations.Translation -> Model
updateTextTranslation model textWord translation =
    let
        newTextWord =
            Text.Translations.TextWord.updateTranslation
                (Text.Translations.TextWord.setNoTRCorrectForContext textWord)
                translation
    in
    setTextWord model newTextWord


getNewTranslationForWord : Model -> Text.Translations.TextWord.TextWord -> Maybe String
getNewTranslationForWord model textWord =
    Dict.get (Text.Translations.TextWord.phrase textWord) model.new_translations


updateTranslationsForWord : Model -> Text.Translations.TextWord.TextWord -> String -> Model
updateTranslationsForWord model textWord translationText =
    let
        phrase =
            Text.Translations.TextWord.phrase textWord
    in
    { model | new_translations = Dict.insert phrase translationText model.new_translations }


addTextTranslation : Model -> Text.Translations.TextWord.TextWord -> Text.Translations.Translation -> Model
addTextTranslation model newTextWord _ =
    setTextWord model newTextWord


removeTextTranslation : Model -> Text.Translations.TextWord.TextWord -> Text.Translations.Translation -> Model
removeTextTranslation model textWord translation =
    let
        newTextWord =
            Text.Translations.TextWord.removeTranslation textWord translation
    in
    setTextWord model newTextWord
