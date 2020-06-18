module Text.Translations.Model exposing (..)

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
        first_grammeme_name =
            "aspect"
    in
    Maybe.withDefault first_grammeme_name model.editing_grammeme


editingGrammemeValue : Model -> WordInstance -> String
editingGrammemeValue model word_instance =
    let
        grammeme_name =
            editingGrammeme model

        word_instance_grammemes =
            Maybe.withDefault "" (Text.Translations.Word.Instance.grammemeValue word_instance grammeme_name)
    in
    Maybe.withDefault word_instance_grammemes (Dict.get grammeme_name model.editing_grammemes)


inputGrammeme : Model -> String -> Model
inputGrammeme model new_grammeme_value =
    let
        editing_grammeme_name =
            editingGrammeme model

        old_grammeme_value =
            editingGrammemeValue model
    in
    { model
        | editing_grammemes =
            Dict.insert editing_grammeme_name new_grammeme_value model.editing_grammemes
    }


textWordToWordInstance : TextWord -> WordInstance
textWordToWordInstance text_word =
    let
        section_number =
            Text.Translations.TextWord.sectionNumber text_word

        phrase =
            String.toLower (Text.Translations.TextWord.phrase text_word)

        instance =
            Text.Translations.TextWord.instance text_word
    in
    Text.Translations.Word.Instance.new section_number instance phrase (Just text_word)


refreshTextWordForWordInstance : Model -> WordInstance -> WordInstance
refreshTextWordForWordInstance model word_instance =
    let
        section_number =
            Text.Translations.Word.Instance.sectionNumber word_instance

        instance =
            Text.Translations.Word.Instance.instance word_instance

        phrase =
            Text.Translations.Word.Instance.token word_instance
    in
    case getTextWord model section_number instance phrase of
        Just text_word ->
            Text.Translations.Word.Instance.setTextWord word_instance text_word

        Nothing ->
            word_instance


newWordInstance : Model -> SectionNumber -> Instance -> Token -> WordInstance
newWordInstance model section_number instance token =
    Text.Translations.Word.Instance.new section_number instance token (getTextWord model section_number instance token)


mergingWordInstances : Model -> List WordInstance
mergingWordInstances model =
    OrderedDict.values (mergingWords model)


mergeSiblings : Model -> WordInstance -> List WordInstance
mergeSiblings model word_instance =
    OrderedDict.values <| OrderedDict.remove (Text.Translations.Word.Instance.id word_instance) (mergingWords model)


mergeState : Model -> WordInstance -> Maybe MergeState
mergeState model word_instance =
    let
        other_merging_words =
            mergeSiblings model word_instance
    in
    case mergingWord model word_instance of
        True ->
            case List.length other_merging_words >= 1 of
                True ->
                    Just Mergeable

                False ->
                    Just Cancelable

        False ->
            Nothing


isTextWordPartOfCompoundWord : Model -> TextWord -> Maybe ( Int, Int, Int )
isTextWordPartOfCompoundWord model text_word =
    let
        section_number =
            Text.Translations.TextWord.sectionNumber text_word

        instance =
            Text.Translations.TextWord.instance text_word

        phrase =
            Text.Translations.TextWord.phrase text_word
    in
    isPartOfCompoundWord model section_number instance phrase


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
completeMerge model section_number phrase instance text_words =
    let
        new_model =
            setTextWords model text_words
                |> clearMerge
                |> uneditAllWords

        merged_word_instance =
            newWordInstance new_model section_number instance phrase
    in
    editWord new_model merged_word_instance


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
mergingWord model word_instance =
    OrderedDict.member (Text.Translations.Word.Instance.id word_instance) model.merging_words


addToMergeWords : Model -> WordInstance -> Model
addToMergeWords model word_instance =
    { model
        | merging_words =
            OrderedDict.insert (Text.Translations.Word.Instance.id word_instance) word_instance model.merging_words
    }


removeFromMergeWords : Model -> WordInstance -> Model
removeFromMergeWords model word_instance =
    { model
        | merging_words =
            OrderedDict.remove (Text.Translations.Word.Instance.id word_instance) model.merging_words
    }


instanceCount : Model -> SectionNumber -> Text.Translations.Word -> Int
instanceCount model section_number word =
    case getTextWords model section_number (String.toLower word) of
        Just text_words ->
            Array.length text_words

        Nothing ->
            0


getTextWords : Model -> SectionNumber -> Phrase -> Maybe (Array TextWord)
getTextWords model section_number phrase =
    case getSectionWords model section_number of
        Just words ->
            Dict.get (String.toLower phrase) words

        Nothing ->
            Nothing


editingWord : Model -> String -> Bool
editingWord model word =
    Dict.member (String.toLower word) model.editing_words


wordInstanceKey : WordInstance -> String
wordInstanceKey word_instance =
    Text.Translations.Word.Instance.id word_instance


setGlobalEditLock : Model -> Bool -> Model
setGlobalEditLock model value =
    { model | edit_lock = value }


editWord : Model -> WordInstance -> Model
editWord model word_instance =
    let
        normalized_word =
            String.toLower (Text.Translations.Word.Instance.word word_instance)

        new_edited_words =
            case Dict.get normalized_word model.editing_words of
                Just ref_count ->
                    Dict.insert normalized_word (ref_count + 1) model.editing_words

                Nothing ->
                    Dict.insert normalized_word 0 model.editing_words

        new_editing_word_instances =
            Dict.insert (wordInstanceKey word_instance) True model.editing_word_instances
    in
    { model | editing_words = new_edited_words, editing_word_instances = new_editing_word_instances }


uneditAllWords : Model -> Model
uneditAllWords model =
    { model
        | editing_words = Dict.empty
        , editing_word_instances = Dict.empty
    }


uneditWord : Model -> WordInstance -> Model
uneditWord model word_instance =
    let
        word =
            Text.Translations.Word.Instance.word word_instance

        normalized_word =
            String.toLower word

        new_edited_words =
            case Dict.get normalized_word model.editing_words of
                Just ref_count ->
                    if (ref_count - 1) == -1 then
                        Dict.remove normalized_word model.editing_words

                    else
                        Dict.insert normalized_word (ref_count - 1) model.editing_words

                Nothing ->
                    model.editing_words

        new_editing_word_instances =
            Dict.remove (wordInstanceKey word_instance) model.editing_word_instances

        cancelled_merge_model =
            clearMerge model
    in
    { cancelled_merge_model
        | editing_words = new_edited_words
        , editing_word_instances = new_editing_word_instances
        , editing_grammemes = Dict.empty
    }


editingWordInstance : Model -> WordInstance -> Bool
editingWordInstance model word_instance =
    Dict.member (Text.Translations.Word.Instance.id word_instance) model.editing_word_instances


getTextWord : Model -> SectionNumber -> Int -> Phrase -> Maybe TextWord
getTextWord model section_number instance phrase =
    case getTextWords model section_number (String.toLower phrase) of
        Just text_words ->
            Array.get instance text_words

        -- word not found
        Nothing ->
            Nothing


setTextWords : Model -> List TextWord -> Model
setTextWords model text_words =
    let
        -- ensure we're initializing the arrays in the right order
        sorted_text_words =
            List.sortBy (\text_word -> Text.Translations.TextWord.instance text_word) text_words

        new_model =
            clearEditingFields model
    in
    List.foldl (\text_word model -> setTextWord model text_word) new_model sorted_text_words


getSectionWords : Model -> SectionNumber -> Maybe (Dict Text.Translations.Word (Array TextWord))
getSectionWords model section_number =
    Array.get (sectionNumberToInt section_number) model.words


setSectionWords : Model -> SectionNumber -> Dict Text.Translations.Word (Array TextWord) -> Model
setSectionWords model section_number words =
    { model | words = Array.set (sectionNumberToInt section_number) words model.words }


setTextWordsForPhrase : Model -> SectionNumber -> Phrase -> Array TextWord -> Model
setTextWordsForPhrase model section_number phrase text_words =
    case getSectionWords model section_number of
        Just section_words ->
            setSectionWords model section_number (Dict.insert (String.toLower phrase) text_words section_words)

        Nothing ->
            model


setTextWord : Model -> TextWord -> Model
setTextWord model text_word =
    let
        section_number =
            Text.Translations.TextWord.sectionNumber text_word

        phrase =
            Text.Translations.TextWord.phrase text_word

        instance =
            Text.Translations.TextWord.instance text_word

        new_text_words =
            case getTextWords model section_number phrase of
                Just text_words ->
                    Array.set instance text_word text_words

                -- word not found
                Nothing ->
                    Array.fromList [ text_word ]
    in
    setTextWordsForPhrase model section_number phrase new_text_words


updateTextTranslation : Model -> Text.Translations.TextWord.TextWord -> Translation -> Model
updateTextTranslation model text_word translation =
    let
        new_text_word =
            Text.Translations.TextWord.updateTranslation
                (Text.Translations.TextWord.setNoTRCorrectForContext text_word)
                translation
    in
    setTextWord model new_text_word


getNewTranslationForWord : Model -> TextWord -> Maybe String
getNewTranslationForWord model text_word =
    Dict.get (Text.Translations.TextWord.phrase text_word) model.new_translations


updateTranslationsForWord : Model -> TextWord -> String -> Model
updateTranslationsForWord model text_word translation_text =
    let
        phrase =
            Text.Translations.TextWord.phrase text_word
    in
    { model | new_translations = Dict.insert phrase translation_text model.new_translations }


addTextTranslation : Model -> TextWord -> Translation -> Model
addTextTranslation model new_text_word translation =
    setTextWord model new_text_word


removeTextTranslation : Model -> TextWord -> Translation -> Model
removeTextTranslation model text_word translation =
    let
        new_text_word =
            Text.Translations.TextWord.removeTranslation text_word translation
    in
    setTextWord model new_text_word
