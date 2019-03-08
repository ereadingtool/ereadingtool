module Text.Translations.Model exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)
import Set exposing (Set)

import Text.Model
import Text.Translations exposing (..)

import Text.Translations.TextWord exposing (TextWord)
import Text.Translations.Word.Instance exposing (WordInstance)


type alias Grammemes = Dict String (Maybe String)


type alias Model = {
   words: Dict Text.Translations.Word (Array TextWord)
 , merging_words: Dict String WordInstance
 , editing_grammeme: Maybe String
 , editing_grammemes: Dict String String
 , editing_words: Dict Text.Translations.Word Int
 , editing_word_instances: Dict Text.Translations.Word Bool
 , text: Text.Model.Text
 , new_translations: Dict String String
 , flags: Flags }


init : Flags -> Text.Model.Text -> Model
init flags text = {
   words=Dict.empty
 , merging_words=Dict.empty
 , editing_words=Dict.empty
 , editing_grammeme=Nothing
 , editing_grammemes=Dict.empty
 , editing_word_instances=Dict.empty
 , text=text
 , new_translations=Dict.empty
 , flags=flags }


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
         Set.toList Text.Translations.Word.Instance.grammemeKeys
      |> List.head
      |> Maybe.withDefault "aspect"
  in
    Maybe.withDefault first_grammeme_name model.editing_grammeme

editingGrammemeValue : Model -> WordInstance -> String
editingGrammemeValue model word_instance =
  let
    grammeme_name = editingGrammeme model

    word_instance_grammemes =
      Maybe.withDefault "" (Text.Translations.Word.Instance.grammemeValue word_instance grammeme_name)
  in
    Maybe.withDefault word_instance_grammemes (Dict.get grammeme_name model.editing_grammemes)

inputGrammeme : Model -> String -> Model
inputGrammeme model new_grammeme_value =
  let
    editing_grammeme_name = editingGrammeme model
    old_grammeme_value = editingGrammemeValue model
  in
    { model
      | editing_grammemes =
          Dict.insert editing_grammeme_name new_grammeme_value model.editing_grammemes
    }

newWordInstance : Model -> Instance -> Token -> WordInstance
newWordInstance model instance token =
  Text.Translations.Word.Instance.new instance token (getTextWord model instance token)

mergingWordInstances : Model -> List WordInstance
mergingWordInstances model =
  Dict.values (mergingWords model)

mergeSiblings : Model -> WordInstance -> List WordInstance
mergeSiblings model word_instance =
  Dict.values <| (Dict.remove (Text.Translations.Word.Instance.id word_instance) (mergingWords model))

mergeState : Model -> WordInstance -> Maybe MergeState
mergeState model word_instance =
  let
    other_merging_words = mergeSiblings model word_instance
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

completeMerge : Model -> Phrase -> Instance -> List TextWord -> Model
completeMerge model phrase instance text_words =
  let
    new_model =
         setTextWords model text_words
      |> cancelMerge
      |> uneditAllWords

    merged_word_instance = newWordInstance new_model instance phrase
  in
    editWord new_model merged_word_instance

cancelMerge : Model -> Model
cancelMerge model =
  { model | merging_words = Dict.empty }

isMergingWords : Model -> Bool
isMergingWords model =
  not (Dict.isEmpty model.merging_words)

mergingWords : Model -> Dict String WordInstance
mergingWords model =
  model.merging_words

mergingWord : Model -> WordInstance -> Bool
mergingWord model word_instance =
  Dict.member (Text.Translations.Word.Instance.id word_instance) model.merging_words

addToMergeWords : Model -> WordInstance -> Model
addToMergeWords model word_instance =
  { model |
    merging_words = Dict.insert (Text.Translations.Word.Instance.id word_instance) word_instance model.merging_words }

removeFromMergeWords : Model -> WordInstance -> Model
removeFromMergeWords model word_instance =
  { model |
    merging_words = Dict.remove (Text.Translations.Word.Instance.id word_instance) model.merging_words }

instanceCount : Model -> Text.Translations.Word -> Int
instanceCount model word =
  case getTextWords model word of
    Just text_words ->
      Array.length text_words

    Nothing ->
      0

getTextWords : Model -> Phrase -> Maybe (Array TextWord)
getTextWords model phrase =
  Dict.get phrase model.words

editingWord : Model -> String -> Bool
editingWord model word =
  Dict.member (String.toLower word) model.editing_words

editWord : Model -> WordInstance -> Model
editWord model word_instance =
  let
    normalized_word = String.toLower (Text.Translations.Word.Instance.word word_instance)
    word_instance_id = Text.Translations.Word.Instance.id word_instance

    new_edited_words =
      (case Dict.get normalized_word model.editing_words of
        Just ref_count ->
          Dict.insert normalized_word (ref_count+1) model.editing_words

        Nothing ->
          Dict.insert normalized_word 0 model.editing_words)

    new_editing_word_instances = Dict.insert word_instance_id True model.editing_word_instances
  in
    { model | editing_words = new_edited_words, editing_word_instances = new_editing_word_instances }

uneditAllWords : Model -> Model
uneditAllWords model =
  { model |
     editing_words = Dict.empty
   , editing_word_instances = Dict.empty }

uneditWord : Model -> WordInstance -> Model
uneditWord model word_instance =
  let
    word = Text.Translations.Word.Instance.word word_instance
    normalized_word = String.toLower word

    new_edited_words =
      (case Dict.get normalized_word model.editing_words of
        Just ref_count ->
          if (ref_count - 1) == -1 then
            Dict.remove normalized_word model.editing_words
          else
            Dict.insert normalized_word (ref_count-1) model.editing_words

        Nothing ->
          model.editing_words)

    word_instance_id = Text.Translations.Word.Instance.id word_instance

    new_editing_word_instances = Dict.remove word_instance_id model.editing_word_instances
    cancelled_merge_model = cancelMerge model
  in
   { cancelled_merge_model |
     editing_words = new_edited_words
   , editing_word_instances = new_editing_word_instances
   , editing_grammemes = Dict.empty }

editingWordInstance : Model -> WordInstance -> Bool
editingWordInstance model word_instance =
  Dict.member (Text.Translations.Word.Instance.id word_instance) model.editing_word_instances

getTextWord : Model -> Int -> Phrase -> Maybe TextWord
getTextWord model instance phrase =
  case getTextWords model phrase of
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

    new_model = clearEditingFields model
  in
    List.foldl (\text_word model ->
      let
        phrase = Text.Translations.TextWord.phrase text_word
        instance = Text.Translations.TextWord.instance text_word
      in
        setTextWord model instance phrase text_word)
    new_model sorted_text_words

setTextWordsForPhrase : Model -> Phrase -> List TextWord -> Model
setTextWordsForPhrase model phrase text_words =
  { model | words = Dict.insert (String.toLower phrase) (Array.fromList text_words) model.words }

setTextWord : Model -> Int -> Phrase -> TextWord -> Model
setTextWord model instance phrase text_word =
  let
    new_text_words =
      (case getTextWords model phrase of
        Just text_words ->
          Array.set instance text_word text_words
        -- word not found
        Nothing ->
          Array.fromList [text_word])
   in
     { model | words = Dict.insert phrase new_text_words model.words }

updateTextTranslation : Model -> Int -> Text.Translations.Word -> Translation -> Model
updateTextTranslation model instance word translation =
  case getTextWord model instance word of
    Just text_word ->
      let
        new_text_word =
          Text.Translations.TextWord.updateTranslation
            (Text.Translations.TextWord.setNoTRCorrectForContext text_word) translation
      in
        setTextWord model instance word new_text_word

    -- text word not found
    Nothing ->
      model

getNewTranslationForWord : Model -> TextWord -> Maybe String
getNewTranslationForWord model text_word =
  Dict.get (Text.Translations.TextWord.phrase text_word) model.new_translations

updateTranslationsForWord : Model -> TextWord -> String -> Model
updateTranslationsForWord model text_word translation_text =
  let
    phrase = Text.Translations.TextWord.phrase text_word
  in
    { model | new_translations = Dict.insert phrase translation_text model.new_translations }

addTextTranslation : Model -> Int -> Text.Translations.Word -> Translation -> Model
addTextTranslation model instance word translation =
  case getTextWord model instance word of
    Just text_word ->
      let
        new_text_word = Text.Translations.TextWord.addTranslation text_word translation
      in
        setTextWord model instance word new_text_word

    Nothing ->
      model

removeTextTranslation : Model -> Int -> Text.Translations.Word -> Translation -> Model
removeTextTranslation model instance word translation =
  case getTextWord model instance word of
    Just text_word ->
      let
        new_text_word = Text.Translations.TextWord.removeTranslation text_word translation
      in
        setTextWord model instance word new_text_word

    Nothing ->
      model