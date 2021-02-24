module Text.Translations.Update exposing
    ( retrieveTextWords
    , update
    )

import Api
import Api.Config as Config exposing (Config)
import Api.Endpoint as Endpoint
import Array
import Dict exposing (Dict)
import Http
import Session exposing (Session)
import Task exposing (Task)
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
            ( Text.Translations.Model.uneditAllWords model
            , matchTranslations parentMsg model wordInstance
            )

        UpdatedTextWords (Ok textWords) ->
            ( Text.Translations.Model.setTextWords model textWords, Cmd.none )

        UpdatedTextWord (Ok textWord) ->
            ( Text.Translations.Model.setTextWord model textWord, Cmd.none )

        EditWord wordInstance ->
            ( Text.Translations.Model.editWord model wordInstance
            , Cmd.none
            )

        CloseEditWord wordInstance ->
            ( Text.Translations.Model.uneditWord model wordInstance
            , Cmd.none
            )

        MakeCorrectForContext textWord translation ->
            ( model
            , updateTranslationAsCorrect model.session model.config parentMsg textWord translation
            )

        UpdateTextTranslation (Ok ( textWord, translation )) ->
            ( Text.Translations.Model.updateTextTranslation model textWord translation
            , Cmd.none
            )

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
            mergeWords parentMsg model wordInstances

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
                        Debug.log "error merging text words" mergeResp.error
                in
                ( Text.Translations.Model.clearMerge model, Cmd.none )

        MergedWords (Err err) ->
            let
                _ =
                    Debug.log "error merging text words" err
            in
            ( model, Cmd.none )

        AddToMergeWords wordInstance ->
            ( Text.Translations.Model.addToMergeWords model wordInstance
            , Cmd.none
            )

        RemoveFromMergeWords wordInstance ->
            ( Text.Translations.Model.removeFromMergeWords model wordInstance
            , Cmd.none
            )

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
            ( newModel
            , postMergeWords model.session model.config parentMsg mergingWordInstances
            )

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

        UnmergeWord textWord ->
            let
                wordId =
                    Text.Translations.TextWord.idToInt textWord
            in
            ( model, unmergeWord model.session model.config parentMsg wordId )

        UnmergedWord (Ok unmergeResp) ->
            ( Text.Translations.Model.completeUnmerge
                model
                unmergeResp.section
                unmergeResp.phrase
                unmergeResp.text_words
            , Cmd.none
            )

        UnmergedWord (Err err) ->
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
            ( Text.Translations.Model.updateTranslationsForWord model textWord translationTxt
            , Cmd.none
            )

        AddTextWord wordInstance ->
            ( model
            , addAsTextWord model.session model.config parentMsg model wordInstance
            )

        SubmitNewTranslationForTextWord textWord ->
            case Text.Translations.Model.getNewTranslationForWord model textWord of
                Just translationText ->
                    ( model
                    , postTranslation model.session model.config parentMsg textWord translationText True
                    )

                Nothing ->
                    ( model, Cmd.none )

        SubmittedTextTranslation (Ok ( textWord, translation )) ->
            ( Text.Translations.Model.addTextTranslation model textWord translation
            , Cmd.none
            )

        -- handle user-friendly msgs
        SubmittedTextTranslation (Err err) ->
            let
                _ =
                    Debug.log "error decoding adding text translations" err
            in
            ( model, Cmd.none )

        DeleteTranslation textWord textTranslation ->
            ( model
            , deleteTranslation model.session model.config parentMsg textWord textTranslation
            )

        DeletedTranslation (Ok resp) ->
            ( Text.Translations.Model.removeTextTranslation model resp.text_word resp.translation
            , Cmd.none
            )

        -- handle user-friendly msgs
        DeletedTranslation (Err err) ->
            let
                _ =
                    Debug.log "error deleting text translations" err
            in
            ( model, Cmd.none )

        SelectGrammemeForEditing _ grammemeName ->
            ( Text.Translations.Model.selectGrammemeForEditing model grammemeName
            , Cmd.none
            )

        InputGrammeme _ grammemeValue ->
            ( Text.Translations.Model.inputGrammeme model grammemeValue
            , Cmd.none
            )

        SaveEditedGrammemes wordInstance ->
            ( model
            , updateGrammemes model.session model.config parentMsg wordInstance model.editing_grammemes
            )

        RemoveGrammeme _ _ ->
            ( model, Cmd.none )


mergeWords : (Msg -> msg) -> Model -> List WordInstance -> ( Model, Cmd msg )
mergeWords toMsg model wordInstances =
    if Text.Translations.Word.Instance.canMergeWords wordInstances then
        -- all word instances are ready to merge
        ( model
        , postMergeWords model.session model.config toMsg wordInstances
        )

    else
        -- lock editing on the page and instantiate some asynchronous tasks to associate text words with these
        -- word instances
        let
            wordInstancesWithNoTextWords =
                List.filter (Text.Translations.Word.Instance.hasTextWord >> not) wordInstances
        in
        ( setGlobalEditLock model True
        , attemptToAddTextWords model wordInstancesWithNoTextWords toMsg
        )


attemptToAddTextWords : Model -> List WordInstance -> (Msg -> msg) -> Cmd msg
attemptToAddTextWords model wordInstancesWithNoTextWord toMsg =
    Task.attempt (handleAddTextWords toMsg wordInstancesWithNoTextWord) <|
        Task.sequence <|
            List.map (addAsTextWordRequest model) wordInstancesWithNoTextWord


handleAddTextWords : (Msg -> msg) -> List WordInstance -> Result Http.Error (List TextWord) -> msg
handleAddTextWords parentMsg _ result =
    case result of
        Err err ->
            (MergeFail >> parentMsg) err

        Ok textWords ->
            (AddedTextWordsForMerge >> parentMsg) textWords


addAsTextWordRequest : Model -> WordInstance -> Task Http.Error TextWord
addAsTextWordRequest model wordInstance =
    Api.postTask
        (Endpoint.createWord (Config.restApiUrl model.config))
        (Session.cred model.session)
        (Http.jsonBody <|
            Text.Translations.Word.Instance.Encode.textWordAddEncoder model.text_id wordInstance
        )
        Text.Translations.Decode.textWordInstanceDecoder


addAsTextWord :
    Session
    -> Config
    -> (Msg -> msg)
    -> Model
    -> WordInstance
    -> Cmd msg
addAsTextWord session config toMsg model wordInstance =
    Api.post
        (Endpoint.createWord (Config.restApiUrl config))
        (Session.cred session)
        (Http.jsonBody <|
            Text.Translations.Word.Instance.Encode.textWordAddEncoder model.text_id wordInstance
        )
        (UpdatedTextWord >> toMsg)
        Text.Translations.Decode.textWordInstanceDecoder


postMergeWords :
    Session
    -> Config
    -> (Msg -> msg)
    -> List WordInstance
    -> Cmd msg
postMergeWords session config toMsg wordInstances =
    let
        textWords =
            List.filterMap
                (\instance ->
                    Text.Translations.Word.Instance.textWord instance
                )
                wordInstances
    in
    Api.post
        (Endpoint.mergeWords (Config.restApiUrl config))
        (Session.cred session)
        (Http.jsonBody <|
            Text.Translations.Encode.textWordMergeEncoder textWords
        )
        (MergedWords >> toMsg)
        Text.Translations.Decode.textWordMergeDecoder


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
                        matchTransltns =
                            putMatchTranslations model.session model.config parentMsg
                    in
                    case Text.Translations.Model.getTextWords model sectionNumber word of
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


deleteTranslation :
    Session
    -> Config
    -> (Msg -> msg)
    -> TextWord
    -> Translation
    -> Cmd msg
deleteTranslation session config toMsg word translation =
    Api.delete
        (Endpoint.translation
            (Config.restApiUrl config)
            (Text.Translations.TextWord.idToInt word)
            translation.id
        )
        (Session.cred session)
        (Http.jsonBody <|
            Text.Translations.Encode.deleteTextTranslationEncode translation.id
        )
        (DeletedTranslation >> toMsg)
        Text.Translations.Decode.textTranslationRemoveRespDecoder


putMatchTranslations :
    Session
    -> Config
    -> (Msg -> msg)
    -> List Translation
    -> List TextWord
    -> Cmd msg
putMatchTranslations session config toMsg translations textWords =
    Api.put
        (Endpoint.matchTranslation (Config.restApiUrl config))
        (Session.cred session)
        (Http.jsonBody <|
            Text.Translations.Encode.textTranslationsMergeEncoder translations textWords
        )
        (UpdatedTextWords >> toMsg)
        Text.Translations.Decode.textWordInstancesDecoder


updateGrammemes :
    Session
    -> Config
    -> (Msg -> msg)
    -> WordInstance
    -> Dict String String
    -> Cmd msg
updateGrammemes session config toMsg wordInstance grammemes =
    case Text.Translations.Word.Instance.textWord wordInstance of
        Just textWord ->
            Api.put
                (Endpoint.word
                    (Config.restApiUrl config)
                    (Text.Translations.TextWord.idToInt textWord)
                )
                (Session.cred session)
                (Http.jsonBody <|
                    Text.Translations.Encode.grammemesEncoder textWord grammemes
                )
                (UpdatedTextWord >> toMsg)
                Text.Translations.Decode.textWordInstanceDecoder

        -- no text word to update
        Nothing ->
            Cmd.none


postTranslation :
    Session
    -> Config
    -> (Msg -> msg)
    -> TextWord
    -> String
    -> Bool
    -> Cmd msg
postTranslation session config toMsg textWord translationText correctForContext =
    Api.post
        (Endpoint.createTranslation (Config.restApiUrl config)
            (Text.Translations.TextWord.idToInt textWord)
        )
        (Session.cred session)
        (Http.jsonBody <|
            Text.Translations.Encode.newTextTranslationEncoder translationText correctForContext
        )
        (SubmittedTextTranslation >> toMsg)
        Text.Translations.Decode.textTranslationUpdateRespDecoder


updateTranslationAsCorrect :
    Session
    -> Config
    -> (Msg -> msg)
    -> TextWord
    -> Translation
    -> Cmd msg
updateTranslationAsCorrect session config toMsg textWord translation =
    Api.put
        (Endpoint.translation
            (Config.restApiUrl config)
            (Text.Translations.TextWord.idToInt textWord)
            translation.id
        )
        (Session.cred session)
        (Http.jsonBody <|
            Text.Translations.Encode.textTranslationAsCorrectEncoder
                { translation | correct_for_context = True }
        )
        (UpdateTextTranslation >> toMsg)
        Text.Translations.Decode.textTranslationUpdateRespDecoder


retrieveTextWords :
    Session
    -> Config
    -> (Msg -> msg)
    -> Maybe Int
    -> Cmd msg
retrieveTextWords session config toMsg textId =
    case textId of
        Just id ->
            Api.get
                (Endpoint.text (Config.restApiUrl config) id [ ( "text_words", "list" ) ])
                (Session.cred session)
                (UpdateTextTranslations >> toMsg)
                Text.Translations.Decode.textWordDictInstancesDecoder

        Nothing ->
            Cmd.none


unmergeWord :
    Session
    -> Config
    -> (Msg -> msg)
    -> Int
    -> Cmd msg
unmergeWord session config toMsg wordId =
    Api.delete
        (Endpoint.unmergeWord (Config.restApiUrl config) wordId)
        (Session.cred session)
        Http.emptyBody
        (UnmergedWord >> toMsg)
        Text.Translations.Decode.textWordMergeDecoder
