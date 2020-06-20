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
update parent_msg msg model =
    case msg of
        MatchTranslations word_instance ->
            ( model, matchTranslations parent_msg model word_instance )

        UpdatedTextWords (Ok text_words) ->
            ( Text.Translations.Model.setTextWords model text_words, Cmd.none )

        UpdatedTextWord (Ok text_word) ->
            ( Text.Translations.Model.setTextWord model text_word, Cmd.none )

        EditWord word_instance ->
            ( Text.Translations.Model.editWord model word_instance, Cmd.none )

        CloseEditWord word_instance ->
            ( Text.Translations.Model.uneditWord model word_instance, Cmd.none )

        MakeCorrectForContext translation ->
            ( model, updateTranslationAsCorrect parent_msg model.flags.csrftoken translation )

        UpdateTextTranslation (Ok ( text_word, translation )) ->
            ( Text.Translations.Model.updateTextTranslation model text_word translation, Cmd.none )

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

        MergeWords word_instances ->
            mergeWords parent_msg model model.flags.csrftoken word_instances

        MergedWords (Ok merge_resp) ->
            if merge_resp.grouped then
                ( Text.Translations.Model.completeMerge
                    model
                    merge_resp.section
                    merge_resp.phrase
                    merge_resp.instance
                    merge_resp.text_words
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

        AddToMergeWords word_instance ->
            ( Text.Translations.Model.addToMergeWords model word_instance, Cmd.none )

        RemoveFromMergeWords word_instance ->
            ( Text.Translations.Model.removeFromMergeWords model word_instance, Cmd.none )

        AddedTextWordsForMerge text_words ->
            let
                new_model =
                    Text.Translations.Model.setTextWords model text_words

                -- update merging words with text words
                merging_word_instances =
                    List.map
                        (\word_instance ->
                            if (Text.Translations.Word.Instance.hasTextWord >> not) word_instance then
                                Text.Translations.Model.refreshTextWordForWordInstance new_model word_instance

                            else
                                word_instance
                        )
                        (Text.Translations.Model.mergingWordInstances new_model)
            in
            -- merge
            ( new_model, postMergeWords parent_msg new_model model.flags.csrftoken merging_word_instances )

        MergeFail err ->
            let
                _ =
                    Debug.log "merge failure" err
            in
            ( setGlobalEditLock model False, Cmd.none )

        DeleteTextWord text_word ->
            ( model, Cmd.none )

        DeletedTextWord text_word ->
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

        UpdateNewTranslationForTextWord text_word translation_text ->
            ( Text.Translations.Model.updateTranslationsForWord model text_word translation_text, Cmd.none )

        AddTextWord word_instance ->
            ( model, addAsTextWord parent_msg model model.flags.csrftoken word_instance )

        SubmitNewTranslationForTextWord text_word ->
            case Text.Translations.Model.getNewTranslationForWord model text_word of
                Just translation_text ->
                    ( model, postTranslation parent_msg model.flags.csrftoken text_word translation_text True )

                Nothing ->
                    ( model, Cmd.none )

        SubmittedTextTranslation (Ok ( text_word, translation )) ->
            ( Text.Translations.Model.addTextTranslation model text_word translation, Cmd.none )

        -- handle user-friendly msgs
        SubmittedTextTranslation (Err err) ->
            let
                _ =
                    Debug.log "error decoding adding text translations" err
            in
            ( model, Cmd.none )

        DeleteTranslation text_word text_translation ->
            ( model, deleteTranslation parent_msg model.flags.csrftoken text_word text_translation )

        DeletedTranslation (Ok resp) ->
            ( Text.Translations.Model.removeTextTranslation model resp.text_word resp.translation, Cmd.none )

        -- handle user-friendly msgs
        DeletedTranslation (Err err) ->
            let
                _ =
                    Debug.log "error deleting text translations" err
            in
            ( model, Cmd.none )

        SelectGrammemeForEditing word_instance grammeme_name ->
            ( Text.Translations.Model.selectGrammemeForEditing model grammeme_name, Cmd.none )

        InputGrammeme word_instance grammeme_value ->
            ( Text.Translations.Model.inputGrammeme model grammeme_value, Cmd.none )

        SaveEditedGrammemes word_instance ->
            ( model, updateGrammemes parent_msg model.flags.csrftoken word_instance model.editing_grammemes )

        RemoveGrammeme word_instance grammeme_str ->
            ( model, Cmd.none )


mergeWords : (Msg -> msg) -> Model -> Flags.CSRFToken -> List WordInstance -> ( Model, Cmd msg )
mergeWords parent_msg model csrftoken word_instances =
    if Text.Translations.Word.Instance.canMergeWords word_instances then
        -- all word instances are ready to merge
        ( model, postMergeWords parent_msg model model.flags.csrftoken word_instances )

    else
        -- lock editing on the page and instantiate some asynchronous tasks to associate text words with these
        -- word instances
        let
            word_instances_with_no_text_words =
                List.filter (Text.Translations.Word.Instance.hasTextWord >> not) word_instances
        in
        ( setGlobalEditLock model True
        , attemptToAddTextWords parent_msg model model.flags.csrftoken word_instances_with_no_text_words
        )


handleAddTextWords : (Msg -> msg) -> List WordInstance -> Result Http.Error (List TextWord) -> msg
handleAddTextWords parent_msg word_instances_with_no_text_word result =
    case result of
        Err err ->
            (MergeFail >> parent_msg) err

        Ok text_words ->
            (AddedTextWordsForMerge >> parent_msg) text_words


attemptToAddTextWords : (Msg -> msg) -> Model -> Flags.CSRFToken -> List WordInstance -> Cmd msg
attemptToAddTextWords parent_msg model csrftoken word_instances_with_no_text_word =
    Task.attempt (handleAddTextWords parent_msg word_instances_with_no_text_word) <|
        Task.sequence <|
            List.map Http.toTask <|
                List.map (addAsTextWordRequest model csrftoken) word_instances_with_no_text_word


addAsTextWordRequest : Model -> Flags.CSRFToken -> WordInstance -> Http.Request TextWord
addAsTextWordRequest model csrftoken word_instance =
    let
        endpoint_uri =
            Text.Translations.addTextWordEndpointToString model.add_as_text_word_endpoint

        headers =
            [ Http.header "X-CSRFToken" csrftoken ]

        encoded_text_word =
            Text.Translations.Word.Instance.Encode.textWordAddEncoder model.text_id word_instance

        body =
            Http.jsonBody encoded_text_word
    in
    HttpHelpers.post_with_headers endpoint_uri headers body Text.Translations.Decode.textWordInstanceDecoder


addAsTextWord : (Msg -> msg) -> Model -> Flags.CSRFToken -> WordInstance -> Cmd msg
addAsTextWord parent_msg model csrftoken word_instance =
    Http.send (parent_msg << UpdatedTextWord) (addAsTextWordRequest model csrftoken word_instance)


postMergeWords : (Msg -> msg) -> Model -> Flags.CSRFToken -> List WordInstance -> Cmd msg
postMergeWords parent_msg model csrftoken word_instances =
    let
        endpoint_url =
            Text.Translations.mergeTextWordEndpointToString model.merge_textword_endpoint

        headers =
            [ Http.header "X-CSRFToken" csrftoken ]

        text_words =
            List.filterMap (\instance -> Text.Translations.Word.Instance.textWord instance) word_instances

        encoded_text_word_ids =
            Text.Translations.Encode.textWordMergeEncoder text_words

        body =
            Http.jsonBody encoded_text_word_ids

        request =
            HttpHelpers.post_with_headers endpoint_url headers body Text.Translations.Decode.textWordMergeDecoder
    in
    Http.send (parent_msg << MergedWords) request


matchTranslations : (Msg -> msg) -> Model -> WordInstance -> Cmd msg
matchTranslations parent_msg model word_instance =
    let
        word =
            String.toLower (Text.Translations.Word.Instance.word word_instance)

        section_number =
            Text.Translations.Word.Instance.sectionNumber word_instance
    in
    case Text.Translations.Word.Instance.textWord word_instance of
        Just text_word ->
            case Text.Translations.TextWord.translations text_word of
                Just new_translations ->
                    let
                        match_translations =
                            putMatchTranslations parent_msg model.text_translation_match_endpoint model.flags.csrftoken
                    in
                    case Text.Translations.Model.getTextWords model section_number word of
                        Just text_words ->
                            match_translations new_translations (Array.toList text_words)

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
deleteTranslation msg csrftoken text_word translation =
    let
        headers =
            [ Http.header "X-CSRFToken" csrftoken ]

        encoded_translation =
            Text.Translations.Encode.deleteTextTranslationEncode translation.id

        body =
            Http.jsonBody encoded_translation

        request =
            HttpHelpers.delete_with_headers
                translation.endpoint
                headers
                body
                Text.Translations.Decode.textTranslationRemoveRespDecoder
    in
    Http.send (msg << DeletedTranslation) request


putMatchTranslations : (Msg -> msg) -> TextTranslationMatchEndpoint -> Flags.CSRFToken -> List Translation -> List TextWord -> Cmd msg
putMatchTranslations msg text_translation_api_match_endpoint csrftoken translations text_words =
    let
        endpoint_uri =
            Text.Translations.textTransMatchEndpointToString text_translation_api_match_endpoint

        headers =
            [ Http.header "X-CSRFToken" csrftoken ]

        encoded_merge_request =
            Text.Translations.Encode.textTranslationsMergeEncoder translations text_words

        body =
            Http.jsonBody encoded_merge_request

        request =
            HttpHelpers.put_with_headers endpoint_uri headers body Text.Translations.Decode.textWordInstancesDecoder
    in
    Http.send (msg << UpdatedTextWords) request


updateGrammemes : (Msg -> msg) -> Flags.CSRFToken -> WordInstance -> Dict String String -> Cmd msg
updateGrammemes msg csrftoken word_instance grammemes =
    case Text.Translations.Word.Instance.textWord word_instance of
        Just text_word ->
            let
                headers =
                    [ Http.header "X-CSRFToken" csrftoken ]

                text_word_endpoint =
                    Text.Translations.TextWord.textWordEndpoint text_word

                encoded_grammemes =
                    Text.Translations.Encode.grammemesEncoder text_word grammemes

                body =
                    Http.jsonBody encoded_grammemes

                request =
                    HttpHelpers.put_with_headers
                        text_word_endpoint
                        headers
                        body
                        Text.Translations.Decode.textWordInstanceDecoder
            in
            Http.send (msg << UpdatedTextWord) request

        -- no text word to update
        Nothing ->
            Cmd.none


postTranslation : (Msg -> msg) -> Flags.CSRFToken -> TextWord -> String -> Bool -> Cmd msg
postTranslation msg csrftoken text_word translation_text correct_for_context =
    let
        endpoint_uri =
            Text.Translations.TextWord.translationsEndpoint text_word

        headers =
            [ Http.header "X-CSRFToken" csrftoken ]

        encoded_translation =
            Text.Translations.Encode.newTextTranslationEncoder translation_text correct_for_context

        body =
            Http.jsonBody encoded_translation

        request =
            HttpHelpers.post_with_headers endpoint_uri headers body Text.Translations.Decode.textTranslationUpdateRespDecoder
    in
    Http.send (msg << SubmittedTextTranslation) request


updateTranslationAsCorrect : (Msg -> msg) -> Flags.CSRFToken -> Translation -> Cmd msg
updateTranslationAsCorrect msg csrftoken translation =
    let
        headers =
            [ Http.header "X-CSRFToken" csrftoken ]

        encoded_translation =
            Text.Translations.Encode.textTranslationAsCorrectEncoder { translation | correct_for_context = True }

        body =
            Http.jsonBody encoded_translation

        request =
            HttpHelpers.put_with_headers
                translation.endpoint
                headers
                body
                Text.Translations.Decode.textTranslationUpdateRespDecoder
    in
    Http.send (msg << UpdateTextTranslation) request


retrieveTextWords : (Msg -> msg) -> Admin.Text.TextAPIEndpoint -> Maybe Int -> Cmd msg
retrieveTextWords msg text_api_endpoint text_id =
    case text_id of
        Just id ->
            let
                text_api_endpoint_url =
                    Admin.Text.textEndpointToString text_api_endpoint

                request =
                    Http.get
                        (String.join "?"
                            [ String.join "" [ text_api_endpoint_url, toString id, "/" ], "text_words=list" ]
                        )
                        Text.Translations.Decode.textWordDictInstancesDecoder
            in
            Http.send (msg << UpdateTextTranslations) request

        Nothing ->
            Cmd.none
