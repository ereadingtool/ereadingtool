module InstructorAdmin.Text.Translations.Update exposing
    ( retrieveTextWords
    , update
    )

import Array
import Dict exposing (Dict)
import Flags
import Http
import InstructorAdmin.Admin.Text
import InstructorAdmin.Text.Translations as Translations exposing (..)
import InstructorAdmin.Text.Translations.Decode as TranslationsDecode
import InstructorAdmin.Text.Translations.Encode as TranslationsEncode
import InstructorAdmin.Text.Translations.Model as TranslationsModel exposing (..)
import InstructorAdmin.Text.Translations.Msg exposing (Msg)
import InstructorAdmin.Text.Translations.TextWord as TranslationsTextWord exposing (TextWord)
import InstructorAdmin.Text.Translations.Word.Instance as TranslationsWordInstance exposing (WordInstance)
import InstructorAdmin.Text.Translations.Word.Instance.Encode as TranslationsWordInstanceEncode
import Task
import Utils.HttpHelpers as HttpHelpers


update : (Msg -> msg) -> Msg -> Model -> ( Model, Cmd msg )
update parentMsg msg model =
    case msg of
        MatchTranslations wordInstance ->
            ( model, matchTranslations parentMsg model wordInstance )

        UpdatedTextWords (Ok textWords) ->
            ( TranslationsModel.setTextWords model textWords, Cmd.none )

        UpdatedTextWord (Ok textWord) ->
            ( TranslationsModel.setTextWord model textWord, Cmd.none )

        EditWord wordInstance ->
            ( TranslationsModel.editWord model wordInstance, Cmd.none )

        CloseEditWord wordInstance ->
            ( TranslationsModel.uneditWord model wordInstance, Cmd.none )

        MakeCorrectForContext translation ->
            ( model, updateTranslationAsCorrect parentMsg model.flags.csrftoken translation )

        UpdateTextTranslation (Ok ( textWord, translation )) ->
            ( TranslationsModel.updateTextTranslation model textWord translation, Cmd.none )

        UpdatedTextWords (Err err) ->
            let
                _ =
                    Debug.log "error updating text words" err
            in
            ( model, Cmd.none )

        UpdatedTextWord (Err err) ->
            let
                _ =
                    Debug.log "error updating text word" err
            in
            ( model, Cmd.none )

        MergeWords wordInstances ->
            mergeWords parentMsg model model.flags.csrftoken wordInstances

        MergedWords (Ok mergeResp) ->
            if mergeResp.grouped then
                ( TranslationsModel.completeMerge
                    model
                    mergeResp.section
                    mergeResp.phrase
                    mergeResp.instance
                    mergeResp.text_words
                , Cmd.none
                )

            else
                let
                    _ =
                        Debug.log "error merging text words" mergeResp.error
                in
                ( TranslationsModel.clearMerge model, Cmd.none )

        MergedWords (Err err) ->
            let
                _ =
                    Debug.log "error merging text words" err
            in
            ( model, Cmd.none )

        AddToMergeWords wordInstance ->
            ( TranslationsModel.addToMergeWords model wordInstance, Cmd.none )

        RemoveFromMergeWords wordInstance ->
            ( TranslationsModel.removeFromMergeWords model wordInstance, Cmd.none )

        AddedTextWordsForMerge textWords ->
            let
                newModel =
                    TranslationsModel.setTextWords model textWords

                -- update merging words with text words
                mergingWordInstances =
                    List.map
                        (\wordInstance ->
                            if (TranslationsWordInstance.hasTextWord >> not) wordInstance then
                                TranslationsModel.refreshTextWordForWordInstance newModel wordInstance

                            else
                                wordInstance
                        )
                        (TranslationsModel.mergingWordInstances newModel)
            in
            -- merge
            ( newModel, postMergeWords parentMsg newModel model.flags.csrftoken mergingWordInstances )

        MergeFail err ->
            let
                _ =
                    Debug.log "merge failure" err
            in
            ( setGlobalEditLock model False, Cmd.none )

        DeleteTextWord _ ->
            ( model, Cmd.none )

        DeletedTextWord _ ->
            ( model, Cmd.none )

        -- handle user-friendly msgs
        UpdateTextTranslation (Err err) ->
            let
                _ =
                    Debug.log "error decoding text translation" err
            in
            ( model, Cmd.none )

        UpdateTextTranslations (Ok words) ->
            ( { model | words = words }, Cmd.none )

        -- handle user-friendly msgs
        UpdateTextTranslations (Err err) ->
            let
                _ =
                    Debug.log "error decoding text translations" err
            in
            ( model, Cmd.none )

        UpdateNewTranslationForTextWord textWord translationTxt ->
            ( TranslationsModel.updateTranslationsForWord model textWord translationTxt, Cmd.none )

        AddTextWord wordInstance ->
            ( model, addAsTextWord parentMsg model model.flags.csrftoken wordInstance )

        SubmitNewTranslationForTextWord textWord ->
            case TranslationsModel.getNewTranslationForWord model textWord of
                Just translationText ->
                    ( model, postTranslation parentMsg model.flags.csrftoken textWord translationText True )

                Nothing ->
                    ( model, Cmd.none )

        SubmittedTextTranslation (Ok ( textWord, translation )) ->
            ( TranslationsModel.addTextTranslation model textWord translation, Cmd.none )

        -- handle user-friendly msgs
        SubmittedTextTranslation (Err err) ->
            let
                _ =
                    Debug.log "error decoding adding text translations" err
            in
            ( model, Cmd.none )

        DeleteTranslation textWord textTranslation ->
            ( model, deleteTranslation parentMsg model.flags.csrftoken textWord textTranslation )

        DeletedTranslation (Ok resp) ->
            ( TranslationsModel.removeTextTranslation model resp.text_word resp.translation, Cmd.none )

        -- handle user-friendly msgs
        DeletedTranslation (Err err) ->
            let
                _ =
                    Debug.log "error deleting text translations" err
            in
            ( model, Cmd.none )

        SelectGrammemeForEditing _ grammemeName ->
            ( TranslationsModel.selectGrammemeForEditing model grammemeName, Cmd.none )

        InputGrammeme _ grammemeValue ->
            ( TranslationsModel.inputGrammeme model grammemeValue, Cmd.none )

        SaveEditedGrammemes wordInstance ->
            ( model, updateGrammemes parentMsg model.flags.csrftoken wordInstance model.editing_grammemes )

        RemoveGrammeme _ _ ->
            ( model, Cmd.none )


mergeWords : (Msg -> msg) -> Model -> Flags.CSRFToken -> List WordInstance -> ( Model, Cmd msg )
mergeWords parentMsg model _ wordInstances =
    if TranslationsWordInstance.canMergeWords wordInstances then
        -- all word instances are ready to merge
        ( model, postMergeWords parentMsg model model.flags.csrftoken wordInstances )

    else
        -- lock editing on the page and instantiate some asynchronous tasks to associate text words with these
        -- word instances
        let
            wordInstancesWithNoTextWords =
                List.filter (TranslationsWordInstance.hasTextWord >> not) wordInstances
        in
        ( setGlobalEditLock model True
        , attemptToAddTextWords parentMsg model model.flags.csrftoken wordInstancesWithNoTextWords
        )


handleAddTextWords : (Msg -> msg) -> List WordInstance -> Result Http.Error (List TextWord) -> msg
handleAddTextWords parentMsg _ result =
    case result of
        Err err ->
            (MergeFail >> parentMsg) err

        Ok textWords ->
            (AddedTextWordsForMerge >> parentMsg) textWords


attemptToAddTextWords : (Msg -> msg) -> Model -> Flags.CSRFToken -> List WordInstance -> Cmd msg
attemptToAddTextWords parentMsg model csrftoken wordInstancesWithNoTextWord =
    Task.attempt (handleAddTextWords parentMsg wordInstancesWithNoTextWord) <|
        Task.sequence <|
            List.map Http.toTask <|
                List.map (addAsTextWordRequest model csrftoken) wordInstancesWithNoTextWord


addAsTextWordRequest : Model -> Flags.CSRFToken -> WordInstance -> Http.Request TextWord
addAsTextWordRequest model csrftoken wordInstance =
    let
        endpointUri =
            Translations.addTextWordEndpointToString model.add_as_text_word_endpoint

        headers =
            [ Http.header "X-CSRFToken" csrftoken ]

        encodedTextWord =
            TranslationsWordInstanceEncode.textWordAddEncoder model.text_id wordInstance

        body =
            Http.jsonBody encodedTextWord
    in
    HttpHelpers.post_with_headers endpointUri headers body TranslationsDecode.textWordInstanceDecoder


addAsTextWord : (Msg -> msg) -> Model -> Flags.CSRFToken -> WordInstance -> Cmd msg
addAsTextWord parentMsg model csrftoken wordInstance =
    Http.send (parentMsg << UpdatedTextWord) (addAsTextWordRequest model csrftoken wordInstance)


postMergeWords : (Msg -> msg) -> Model -> Flags.CSRFToken -> List WordInstance -> Cmd msg
postMergeWords parentMsg model csrftoken wordInstances =
    let
        endpointUrl =
            Translations.mergeTextWordEndpointToString model.merge_textword_endpoint

        headers =
            [ Http.header "X-CSRFToken" csrftoken ]

        textWords =
            List.filterMap (\instance -> TranslationsWordInstance.textWord instance) wordInstances

        encodedTextWordIds =
            TranslationsEncode.textWordMergeEncoder textWords

        body =
            Http.jsonBody encodedTextWordIds

        request =
            HttpHelpers.post_with_headers endpointUrl headers body TranslationsDecode.textWordMergeDecoder
    in
    Http.send (parentMsg << MergedWords) request


matchTranslations : (Msg -> msg) -> Model -> WordInstance -> Cmd msg
matchTranslations parentMsg model wordInstance =
    let
        word =
            String.toLower (TranslationsWordInstance.word wordInstance)

        sectionNumber =
            TranslationsWordInstance.sectionNumber wordInstance
    in
    case TranslationsWordInstance.textWord wordInstance of
        Just textWord ->
            case TranslationsTextWord.translations textWord of
                Just newTranslations ->
                    let
                        matchTransltns =
                            putMatchTranslations parentMsg model.text_translation_match_endpoint model.flags.csrftoken
                    in
                    case TranslationsModel.getTextWords model sectionNumber word of
                        Just textWords ->
                            matchTransltns newTranslations (Array.toList textWords)

                        -- no text words associated with this word
                        Nothing ->
                            Cmd.none

                -- no translations to match
                Nothing ->
                    Cmd.none

        -- no text word
        Nothing ->
            Cmd.none


deleteTranslation : (Msg -> msg) -> Flags.CSRFToken -> TextWord -> Translation -> Cmd msg
deleteTranslation msg csrftoken _ translation =
    let
        headers =
            [ Http.header "X-CSRFToken" csrftoken ]

        encodedTranslation =
            TranslationsEncode.deleteTextTranslationEncode translation.id

        body =
            Http.jsonBody encodedTranslation

        request =
            HttpHelpers.delete_with_headers
                translation.endpoint
                headers
                body
                TranslationsDecode.textTranslationRemoveRespDecoder
    in
    Http.send (msg << DeletedTranslation) request


putMatchTranslations : (Msg -> msg) -> TextTranslationMatchEndpoint -> Flags.CSRFToken -> List Translation -> List TextWord -> Cmd msg
putMatchTranslations msg textTranslationApiMatchEndpoint csrftoken translations textWords =
    let
        endpointUri =
            Translations.textTransMatchEndpointToString textTranslationApiMatchEndpoint

        headers =
            [ Http.header "X-CSRFToken" csrftoken ]

        encodedMergeRequest =
            TranslationsEncode.textTranslationsMergeEncoder translations textWords

        body =
            Http.jsonBody encodedMergeRequest

        request =
            HttpHelpers.put_with_headers endpointUri headers body TranslationsDecode.textWordInstancesDecoder
    in
    Http.send (msg << UpdatedTextWords) request


updateGrammemes : (Msg -> msg) -> Flags.CSRFToken -> WordInstance -> Dict String String -> Cmd msg
updateGrammemes msg csrftoken wordInstance grammemes =
    case TranslationsWordInstance.textWord wordInstance of
        Just textWord ->
            let
                headers =
                    [ Http.header "X-CSRFToken" csrftoken ]

                textWordEndpoint =
                    TranslationsTextWord.textWordEndpoint textWord

                encodedGrammemes =
                    TranslationsEncode.grammemesEncoder textWord grammemes

                body =
                    Http.jsonBody encodedGrammemes

                request =
                    HttpHelpers.put_with_headers
                        textWordEndpoint
                        headers
                        body
                        TranslationsDecode.textWordInstanceDecoder
            in
            Http.send (msg << UpdatedTextWord) request

        -- no text word to update
        Nothing ->
            Cmd.none


postTranslation : (Msg -> msg) -> Flags.CSRFToken -> TextWord -> String -> Bool -> Cmd msg
postTranslation msg csrftoken textWord translationText correctForContext =
    let
        endpointUri =
            TranslationsTextWord.translationsEndpoint textWord

        headers =
            [ Http.header "X-CSRFToken" csrftoken ]

        encodedTranslation =
            TranslationsEncode.newTextTranslationEncoder translationText correctForContext

        body =
            Http.jsonBody encodedTranslation

        request =
            HttpHelpers.post_with_headers endpointUri headers body TranslationsDecode.textTranslationUpdateRespDecoder
    in
    Http.send (msg << SubmittedTextTranslation) request


updateTranslationAsCorrect : (Msg -> msg) -> Flags.CSRFToken -> Translation -> Cmd msg
updateTranslationAsCorrect msg csrftoken translation =
    let
        headers =
            [ Http.header "X-CSRFToken" csrftoken ]

        encodedTranslation =
            TranslationsEncode.textTranslationAsCorrectEncoder { translation | correct_for_context = True }

        body =
            Http.jsonBody encodedTranslation

        request =
            HttpHelpers.put_with_headers
                translation.endpoint
                headers
                body
                TranslationsDecode.textTranslationUpdateRespDecoder
    in
    Http.send (msg << UpdateTextTranslation) request


retrieveTextWords : (Msg -> msg) -> InstructorAdmin.Admin.Text.TextAPIEndpoint -> Maybe Int -> Cmd msg
retrieveTextWords msg textApiEndpoint textId =
    case textId of
        Just id ->
            let
                textApiEndpointUrl =
                    InstructorAdmin.Admin.Text.textEndpointToString textApiEndpoint

                request =
                    Http.get
                        (String.join "?"
                            [ String.join "" [ textApiEndpointUrl, String.fromInt id, "/" ], "text_words=list" ]
                        )
                        TranslationsDecode.textWordDictInstancesDecoder
            in
            Http.send (msg << UpdateTextTranslations) request

        Nothing ->
            Cmd.none
