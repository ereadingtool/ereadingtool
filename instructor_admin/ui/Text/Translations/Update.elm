module Text.Translations.Update exposing
    ( retrieveTextWords
    , update
    )

import Admin.Text
import Array
import Dict exposing (Dict)
import Flags
import Http
import HttpHelpers
import Task
import Text.Translations exposing (..)
import Text.Translations.Decode
import Text.Translations.Encode
import Text.Translations.Model exposing (..)
import Text.Translations.Msg exposing (..)
import Text.Translations.TextWord exposing (TextWord)
import Text.Translations.Word.Instance exposing (WordInstance)
import Text.Translations.Word.Instance.Encode


update : (Msg -> msg) -> Msg -> Model -> ( Model, Cmd msg )
update parentMsg msg model =
    case msg of
        MatchTranslations wordInstance ->
            ( model, matchTranslations parentMsg model wordInstance )

        UpdatedTextWords (Ok textWords) ->
            ( Text.Translations.Model.setTextWords model textWords, Cmd.none )

        UpdatedTextWord (Ok textWord) ->
            ( Text.Translations.Model.setTextWord model textWord, Cmd.none )

        EditWord wordInstance ->
            ( Text.Translations.Model.editWord model wordInstance, Cmd.none )

        CloseEditWord wordInstance ->
            ( Text.Translations.Model.uneditWord model wordInstance, Cmd.none )

        MakeCorrectForContext translation ->
            ( model, updateTranslationAsCorrect parentMsg model.flags.csrftoken translation )

        UpdateTextTranslation (Ok ( textWord, translation )) ->
            ( Text.Translations.Model.updateTextTranslation model textWord translation, Cmd.none )

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
                ( Text.Translations.Model.completeMerge
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
                        Debug.log "error merging text words" merge_resp.error
                in
                ( Text.Translations.Model.clearMerge model, Cmd.none )

        MergedWords (Err err) ->
            let
                _ =
                    Debug.log "error merging text words" err
            in
            ( model, Cmd.none )

        AddToMergeWords wordInstance ->
            ( Text.Translations.Model.addToMergeWords model wordInstance, Cmd.none )

        RemoveFromMergeWords wordInstance ->
            ( Text.Translations.Model.removeFromMergeWords model wordInstance, Cmd.none )

        AddedTextWordsForMerge textWords ->
            let
                newModel =
                    Text.Translations.Model.setTextWords model textWords

                -- update merging words with text words
                mergingWordInstances =
                    List.map
                        (\wordInstance ->
                            if (Text.Translations.Word.Instance.hasTextWord >> not) wordInstance then
                                Text.Translations.Model.refreshTextWordForWordInstance newModel wordInstance

                            else
                                wordInstance
                        )
                        (Text.Translations.Model.mergingWordInstances newModel)
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

        UpdateNewTranslationForTextWord textWord translationText ->
            ( Text.Translations.Model.updateTranslationsForWord model textWord translationtTxt, Cmd.none )

        AddTextWord wordInstance ->
            ( model, addAsTextWord parentMsg model model.flags.csrftoken wordInstance )

        SubmitNewTranslationForTextWord textWord ->
            case Text.Translations.Model.getNewTranslationForWord model textWord of
                Just translationText ->
                    ( model, postTranslation parentMsg model.flags.csrftoken textWord translationText True )

                Nothing ->
                    ( model, Cmd.none )

        SubmittedTextTranslation (Ok ( textWord, translation )) ->
            ( Text.Translations.Model.addTextTranslation model textWord translation, Cmd.none )

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
            ( Text.Translations.Model.removeTextTranslation model resp.text_word resp.translation, Cmd.none )

        -- handle user-friendly msgs
        DeletedTranslation (Err err) ->
            let
                _ =
                    Debug.log "error deleting text translations" err
            in
            ( model, Cmd.none )

        SelectGrammemeForEditing _ grammemeName ->
            ( Text.Translations.Model.selectGrammemeForEditing model grammemeName, Cmd.none )

        InputGrammeme _ grammemeValue ->
            ( Text.Translations.Model.inputGrammeme model grammemeValue, Cmd.none )

        SaveEditedGrammemes wordInstance ->
            ( model, updateGrammemes parentMsg model.flags.csrftoken wordInstance model.editing_grammemes )

        RemoveGrammeme _ _ ->
            ( model, Cmd.none )


mergeWords : (Msg -> msg) -> Model -> Flags.CSRFToken -> List WordInstance -> ( Model, Cmd msg )
mergeWords parent_msg model _ wordInstances =
    if Text.Translations.Word.Instance.canMergeWords wordInstances then
        -- all word instances are ready to merge
        ( model, postMergeWords parentMsg model model.flags.csrftoken wordInstances )

    else
        -- lock editing on the page and instantiate some asynchronous tasks to associate text words with these
        -- word instances
        let
            wordInstancesWithNoTextWords =
                List.filter (Text.Translations.Word.Instance.hasTextWord >> not) wordInstances
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
            Text.Translations.addTextWordEndpointToString model.add_as_text_word_endpoint

        headers =
            [ Http.header "X-CSRFToken" csrftoken ]

        encodedTextWord =
            Text.Translations.Word.Instance.Encode.textWordAddEncoder model.text_id wordInstance

        body =
            Http.jsonBody encodedTextWord
    in
    HttpHelpers.post_with_headers endpointUri headers body Text.Translations.Decode.textWordInstanceDecoder


addAsTextWord : (Msg -> msg) -> Model -> Flags.CSRFToken -> WordInstance -> Cmd msg
addAsTextWord parentMsg model csrftoken wordInstance =
    Http.send (parentMsg << UpdatedTextWord) (addAsTextWordRequest model csrftoken wordInstance)


postMergeWords : (Msg -> msg) -> Model -> Flags.CSRFToken -> List WordInstance -> Cmd msg
postMergeWords parentMsg model csrftoken wordInstances =
    let
        endpointUrl =
            Text.Translations.mergeTextWordEndpointToString model.merge_textword_endpoint

        headers =
            [ Http.header "X-CSRFToken" csrftoken ]

        textWords =
            List.filterMap (\instance -> Text.Translations.Word.Instance.textWord instance) wordInstances

        encodedTextWordIds =
            Text.Translations.Encode.textWordMergeEncoder textWords

        body =
            Http.jsonBody encodedTextWordIds

        request =
            HttpHelpers.post_with_headers endpointUrl headers body Text.Translations.Decode.textWordMergeDecoder
    in
    Http.send (parent_msg << MergedWords) request


matchTranslations : (Msg -> msg) -> Model -> WordInstance -> Cmd msg
matchTranslations parentMsg model wordInstance =
    let
        word =
            String.toLower (Text.Translations.Word.Instance.word wordInstance)

        sectionNumber =
            Text.Translations.Word.Instance.sectionNumber wordInstance
    in
    case Text.Translations.Word.Instance.textWord wordInstance of
        Just textWord ->
            case Text.Translations.TextWord.translations textWord of
                Just newTranslations ->
                    let
                        matchTranslations =
                            putMatchTranslations parentMsg model.text_translation_match_endpoint model.flags.csrftoken
                    in
                    case Text.Translations.Model.getTextWords model sectionNumber word of
                        Just textWords ->
                            matchTranslations newTranslations (Array.toList textWords)

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
            Text.Translations.Encode.deleteTextTranslationEncode translation.id

        body =
            Http.jsonBody encodedTranslation

        request =
            HttpHelpers.delete_with_headers
                translation.endpoint
                headers
                body
                Text.Translations.Decode.textTranslationRemoveRespDecoder
    in
    Http.send (msg << DeletedTranslation) request


putMatchTranslations : (Msg -> msg) -> TextTranslationMatchEndpoint -> Flags.CSRFToken -> List Translation -> List TextWord -> Cmd msg
putMatchTranslations msg textTranslationApiMatchEndpoint csrftoken translations textWords =
    let
        endpointUri =
            Text.Translations.textTransMatchEndpointToString textTranslationApiMatchEndpoint

        headers =
            [ Http.header "X-CSRFToken" csrftoken ]

        encodedMergeRequest =
            Text.Translations.Encode.textTranslationsMergeEncoder translations textWords

        body =
            Http.jsonBody encodedMergeRequest

        request =
            HttpHelpers.put_with_headers endpointUri headers body Text.Translations.Decode.textWordInstancesDecoder
    in
    Http.send (msg << UpdatedTextWords) request


updateGrammemes : (Msg -> msg) -> Flags.CSRFToken -> WordInstance -> Dict String String -> Cmd msg
updateGrammemes msg csrftoken wordInstance grammemes =
    case Text.Translations.Word.Instance.textWord wordInstance of
        Just textWord ->
            let
                headers =
                    [ Http.header "X-CSRFToken" csrftoken ]

                textWordEndpoint =
                    Text.Translations.TextWord.textWordEndpoint textWord

                encodedGrammemes =
                    Text.Translations.Encode.grammemesEncoder textWord grammemes

                body =
                    Http.jsonBody encodedGrammemes

                request =
                    HttpHelpers.put_with_headers
                        textWordEndpoint
                        headers
                        body
                        Text.Translations.Decode.textWordInstanceDecoder
            in
            Http.send (msg << UpdatedTextWord) request

        -- no text word to update
        Nothing ->
            Cmd.none


postTranslation : (Msg -> msg) -> Flags.CSRFToken -> TextWord -> String -> Bool -> Cmd msg
postTranslation msg csrftoken textWord translationText correctForContext =
    let
        endpointUri =
            Text.Translations.TextWord.translationsEndpoint textWord

        headers =
            [ Http.header "X-CSRFToken" csrftoken ]

        encodedTranslation =
            Text.Translations.Encode.newTextTranslationEncoder translationText correctForContext

        body =
            Http.jsonBody encodedTranslation

        request =
            HttpHelpers.post_with_headers endpointUri headers body Text.Translations.Decode.textTranslationUpdateRespDecoder
    in
    Http.send (msg << SubmittedTextTranslation) request


updateTranslationAsCorrect : (Msg -> msg) -> Flags.CSRFToken -> Translation -> Cmd msg
updateTranslationAsCorrect msg csrftoken translation =
    let
        headers =
            [ Http.header "X-CSRFToken" csrftoken ]

        encodedTranslation =
            Text.Translations.Encode.textTranslationAsCorrectEncoder { translation | correct_for_context = True }

        body =
            Http.jsonBody encodedTranslation

        request =
            HttpHelpers.put_with_headers
                translation.endpoint
                headers
                body
                Text.Translations.Decode.textTranslationUpdateRespDecoder
    in
    Http.send (msg << UpdateTextTranslation) request


retrieveTextWords : (Msg -> msg) -> Admin.Text.TextAPIEndpoint -> Maybe Int -> Cmd msg
retrieveTextWords msg textApiEndpoint textId =
    case textId of
        Just id ->
            let
                textApiEndpointUrl =
                    Admin.Text.textEndpointToString textApiEndpoint

                request =
                    Http.get
                        (String.join "?"
                            [ String.join "" [ textApiEndpointUrl, String.fromInt id, "/" ], "text_words=list" ]
                        )
                        Text.Translations.Decode.textWordDictInstancesDecoder
            in
            Http.send (msg << UpdateTextTranslations) request

        Nothing ->
            Cmd.none
