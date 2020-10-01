module Pages.Text.Edit.Id_Int exposing (..)

import Api
import Api.Config as Config exposing (Config)
import Api.Endpoint as Endpoint
import Browser.Navigation
import Debug
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (attribute)
import Http
import InstructorAdmin.Text.Translations as Translations
import Json.Decode as Decode
import Ports exposing (ckEditorUpdate, clearInputText, confirm, confirmation)
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Task
import Text.Component exposing (TextComponent)
import Text.Decode
import Text.Encode
import Text.Field exposing (TextField(..))
import Text.Model exposing (Text)
import Text.Subscriptions
import Text.Translations.Model as TranslationsModel
import Text.Translations.Msg as TranslationsMsg
import Text.Translations.Update
import Text.Update
import Text.View
import TextEdit exposing (Mode(..), Tab(..))
import Time
import User.Instructor.Profile as InstructorProfile exposing (InstructorProfile)
import User.Profile as Profile


page : Page Params Model Msg
page =
    Page.protectedInstructorApplication
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , save = save
        , load = load
        }


type alias TextsResponseError =
    Dict String String



-- INIT


type alias Params =
    { id : Int }


type alias Model =
    Maybe SafeModel


type SafeModel
    = SafeModel
        { session : Session
        , config : Config
        , mode : Mode
        , profile : InstructorProfile
        , successMessage : Maybe String
        , errorMessage : Maybe String
        , text_component : TextComponent
        , textDifficulties : List Text.Model.TextDifficulty
        , translationsInit : Translations.Flags
        , textTranslationsModel : Maybe TranslationsModel.Model
        , tags : Dict String String
        , writeLocked : Bool
        , selectedTab : Tab
        }


init : Shared.Model -> Url Params -> ( SafeModel, Cmd Msg )
init shared { params } =
    ( SafeModel
        { session = shared.session
        , config = shared.config

        -- the writeLocker is a instructor username string,
        -- and we don't know who it is until we retrieve the text
        , mode = ReadOnlyMode ""
        , successMessage = Nothing
        , errorMessage = Nothing
        , profile = Profile.toInstructorProfile shared.profile
        , text_component = Text.Component.emptyTextComponent
        , textDifficulties = Shared.difficulties
        , translationsInit =
            { session = shared.session
            , config = shared.config
            , add_as_text_word_endpoint_url = "legacyEndpoint"
            , merge_textword_endpoint_url = "legacyEndpoint"
            , text_translation_match_endpoint = "legacyEndpoint"
            , csrftoken = "legacyToken"
            }
        , textTranslationsModel = Nothing
        , tags =
            Dict.fromList <|
                List.map (\tag -> ( tag, tag )) Shared.tags
        , selectedTab = TextTab
        , writeLocked = False
        }
    , Cmd.batch
        [ Task.perform (\_ -> InitTextFieldEditors) (Task.succeed Nothing)
        , getText shared.session shared.config params.id
        ]
    )



-- UPDATE


type Msg
    = SubmittedText
    | GotText (Result Http.Error Text)
    | GotTextCreated (Result Http.Error Text.Decode.TextCreateResp)
    | GotTextUpdated (Result Http.Error Text.Decode.TextUpdateResp)
    | SubmittedTextDelete
    | ConfirmedTextDelete Bool
    | GotTextDeleted (Result Http.Error Text.Decode.TextDeleteResp)
    | InitTextFieldEditors
    | ToggleEditable TextField Bool
    | UpdateTextAttributes String String
    | UpdateTextCkEditors ( String, String )
    | AddTagInput String String
    | DeleteTag String
    | ToggleLock
    | TextLocked (Result Http.Error Text.Decode.TextLockResp)
    | TextUnlocked (Result Http.Error Text.Decode.TextLockResp)
    | ToggleTab Tab
    | ClearMessages Time.Posix
    | TextTagsDecode (Result String (Dict String String))
    | TextTranslationMsg TranslationsMsg.Msg
    | TextComponentMsg Text.Update.Msg


update : Msg -> SafeModel -> ( SafeModel, Cmd Msg )
update msg (SafeModel model) =
    case msg of
        SubmittedText ->
            let
                text =
                    Text.Component.text model.text_component
            in
            case model.mode of
                ReadOnlyMode writeLocker ->
                    ( SafeModel { model | successMessage = Just <| "Text is locked by " ++ writeLocker }, Cmd.none )

                EditMode ->
                    ( SafeModel { model | errorMessage = Nothing, successMessage = Nothing }
                    , updateText model.session model.config text
                    )

                CreateMode ->
                    ( SafeModel { model | errorMessage = Nothing, successMessage = Nothing }
                    , postText model.session model.config text
                    )

        GotText (Ok text) ->
            let
                textComponent =
                    Text.Component.init text
            in
            case text.write_locker of
                Just writeLocker ->
                    if writeLocker /= InstructorProfile.usernameToString (InstructorProfile.username model.profile) then
                        ( SafeModel
                            { model
                                | text_component = textComponent
                                , mode = ReadOnlyMode writeLocker
                                , errorMessage = Just <| "READONLY: text is currently being edited by " ++ writeLocker
                                , writeLocked = True
                            }
                        , Text.Component.reinitialize_ck_editors textComponent
                        )

                    else
                        ( SafeModel
                            { model
                                | text_component = textComponent
                                , mode = EditMode
                                , successMessage = Just <| "editing '" ++ text.title ++ "' text"
                                , writeLocked = True
                            }
                        , Cmd.batch
                            [ Text.Component.reinitialize_ck_editors textComponent
                            , Text.Translations.Update.retrieveTextWords
                                model.session
                                model.config
                                TextTranslationMsg
                                text.id
                            ]
                        )

                Nothing ->
                    case text.id of
                        Just id ->
                            ( SafeModel
                                { model
                                    | text_component = textComponent
                                    , mode = EditMode
                                    , textTranslationsModel =
                                        Just (TranslationsModel.init model.translationsInit id text)
                                    , successMessage = Just <| "editing '" ++ text.title ++ "' text"
                                }
                            , Cmd.batch
                                [ Text.Component.reinitialize_ck_editors textComponent
                                , Text.Translations.Update.retrieveTextWords
                                    model.session
                                    model.config
                                    TextTranslationMsg
                                    text.id
                                ]
                            )

                        Nothing ->
                            ( SafeModel
                                { model
                                    | text_component = textComponent
                                    , mode = EditMode
                                    , errorMessage = Just <| "Something went wrong: no valid text id"
                                }
                            , Text.Component.reinitialize_ck_editors textComponent
                            )

        GotText (Err err) ->
            ( SafeModel model
            , Cmd.none
            )

        GotTextCreated (Ok textCreateResp) ->
            let
                text =
                    Text.Component.text model.text_component
            in
            ( SafeModel
                { model
                    | successMessage = Just <| String.join " " [ " created '" ++ text.title ++ "'" ]
                    , mode = EditMode
                }
            , Browser.Navigation.load textCreateResp.redirect
            )

        GotTextCreated (Err err) ->
            case err of
                Http.BadStatus resp ->
                    -- case Text.Decode.decodeRespErrors resp.body of
                    --     Ok errors ->
                    --         ( SafeModel { model | text_component = Text.Component.update_text_errors model.text_component errors }, Cmd.none )
                    --     _ ->
                    ( SafeModel model, Cmd.none )

                Http.BadBody resp ->
                    let
                        _ =
                            Debug.log "submit text bad payload error" resp
                    in
                    ( SafeModel model, Cmd.none )

                _ ->
                    ( SafeModel model, Cmd.none )

        GotTextUpdated (Ok textUpdateResp) ->
            let
                text =
                    Text.Component.text model.text_component
            in
            ( SafeModel
                { model
                    | successMessage =
                        Just <|
                            String.join " " [ " saved '" ++ text.title ++ "'" ]
                }
            , Cmd.none
            )

        GotTextUpdated (Err err) ->
            case err of
                Http.BadStatus resp ->
                    let
                        _ =
                            Debug.log "update error bad status" resp
                    in
                    -- case Text.Decode.decodeRespErrors resp.body of
                    --     Ok errors ->
                    --         ( SafeModel { model | text_component = Text.Component.update_text_errors model.text_component errors }, Cmd.none )
                    --     _ ->
                    ( SafeModel model, Cmd.none )

                Http.BadBody resp ->
                    let
                        _ =
                            Debug.log "update error bad payload" resp
                    in
                    ( SafeModel model, Cmd.none )

                _ ->
                    ( SafeModel model, Cmd.none )

        SubmittedTextDelete ->
            ( SafeModel model
            , confirm "Are you sure you want to delete this text?"
            )

        GotTextDeleted (Ok textDelete) ->
            let
                _ =
                    Debug.log "text delete" textDelete
            in
            ( SafeModel model, Browser.Navigation.load textDelete.redirect )

        GotTextDeleted (Err httpError) ->
            case httpError of
                Http.BadStatus resp ->
                    let
                        _ =
                            Debug.log "delete text error bad status" resp
                    in
                    -- case Text.Decode.decodeRespErrors resp.body of
                    --     Ok errors ->
                    --         let
                    --             errorsStr =
                    --                 String.join " and " (Dict.values errors)
                    --         in
                    --         ( SafeModel { model | success_msg = Just <| "Error trying to delete the text: " ++ errorsStr }, Cmd.none )
                    --     _ ->
                    ( SafeModel model, Cmd.none )

                Http.BadBody resp ->
                    let
                        _ =
                            Debug.log "delete text error bad payload" resp
                    in
                    ( SafeModel model, Cmd.none )

                _ ->
                    let
                        _ =
                            Debug.log "delete text error bad payload" httpError
                    in
                    ( SafeModel model, Cmd.none )

        ConfirmedTextDelete confirm ->
            if confirm then
                let
                    text =
                        Text.Component.text model.text_component
                in
                ( SafeModel model
                , deleteText model.session model.config text
                )

            else
                ( SafeModel model, Cmd.none )

        InitTextFieldEditors ->
            ( SafeModel model
            , Text.Component.initialize_text_field_ck_editors model.text_component
            )

        ToggleEditable textField editable ->
            let
                ( textComponent, postToggleCmds ) =
                    case textField of
                        Title _ ->
                            ( Text.Component.set_title_editable model.text_component editable
                            , Text.Component.post_toggle_title
                            )

                        Author _ ->
                            ( Text.Component.set_author_editable model.text_component editable
                            , Text.Component.post_toggle_author
                            )

                        Source _ ->
                            ( Text.Component.set_source_editable model.text_component editable
                            , Text.Component.post_toggle_source
                            )

                        _ ->
                            ( model.text_component, \_ -> Cmd.none )
            in
            ( SafeModel { model | text_component = textComponent }
            , postToggleCmds textComponent
            )

        UpdateTextAttributes attrName attrValue ->
            ( SafeModel { model | text_component = Text.Component.set_text_attribute model.text_component attrName attrValue }
            , Cmd.none
            )

        UpdateTextCkEditors ( ckId, ckText ) ->
            let
                textIntroInputId =
                    (Text.Field.text_intro_attrs
                        (Text.Field.intro (Text.Component.text_fields model.text_component))
                    ).input_id

                textConclusionInputId =
                    (Text.Field.text_conclusion_attrs
                        (Text.Field.conclusion (Text.Component.text_fields model.text_component))
                    ).input_id
            in
            if ckId == textIntroInputId then
                ( SafeModel { model | text_component = Text.Component.set_text_attribute model.text_component "introduction" ckText }
                , Cmd.none
                )

            else if ckId == textConclusionInputId then
                ( SafeModel { model | text_component = Text.Component.set_text_attribute model.text_component "conclusion" ckText }
                , Cmd.none
                )

            else
                ( SafeModel model, Cmd.none )

        AddTagInput inputId input ->
            if Dict.member input model.tags then
                ( SafeModel
                    { model
                        | text_component =
                            Text.Component.add_tag model.text_component input
                    }
                , clearInputText inputId
                )

            else
                ( SafeModel model, Cmd.none )

        DeleteTag tag ->
            ( SafeModel
                { model
                    | text_component =
                        Text.Component.remove_tag model.text_component tag
                }
            , Cmd.none
            )

        ToggleLock ->
            let
                text =
                    Text.Component.text model.text_component
            in
            ( SafeModel model
            , if not model.writeLocked then
                postLock model.session model.config text

              else
                deleteLock model.session model.config text
            )

        TextLocked (Ok textLockedResp) ->
            ( SafeModel
                { model
                    | writeLocked = textLockedResp.locked
                    , successMessage =
                        Just "text is locked for editing, other instructors can only view the text while it is locked."
                }
            , Cmd.none
            )

        TextLocked (Err err) ->
            case err of
                Http.BadStatus resp ->
                    let
                        _ =
                            Debug.log "update error bad status" resp
                    in
                    -- case Text.Decode.decodeRespErrors resp.body of
                    --     Ok errors ->
                    --         let
                    --             errors_str =
                    --                 String.join " and " (Dict.values errors)
                    --         in
                    --         ( SafeModel { model | success_msg = Just <| "Error trying to lock the text: " ++ errors_str }, Cmd.none )
                    --     _ ->
                    ( SafeModel model, Cmd.none )

                Http.BadBody resp ->
                    let
                        _ =
                            Debug.log "update error bad payload" resp
                    in
                    ( SafeModel model, Cmd.none )

                _ ->
                    ( SafeModel model, Cmd.none )

        TextUnlocked (Ok textUnlockedResp) ->
            ( SafeModel
                { model
                    | writeLocked = textUnlockedResp.locked
                    , successMessage =
                        Just "text is unlocked for editing, other instructors can now edit the text."
                }
            , Cmd.none
            )

        TextUnlocked (Err err) ->
            case err of
                Http.BadStatus resp ->
                    let
                        _ =
                            Debug.log "update error bad status" resp
                    in
                    -- case Text.Decode.decodeRespErrors resp.body of
                    --     Ok errors ->
                    --         let
                    --             errors_str =
                    --                 String.join " and " (Dict.values errors)
                    --         in
                    --         ( SafeModel { model | success_msg = Just <| "Error trying to unlock the text: " ++ errors_str }, Cmd.none )
                    --     _ ->
                    ( SafeModel model, Cmd.none )

                Http.BadBody resp ->
                    let
                        _ =
                            Debug.log "update error bad payload" resp
                    in
                    ( SafeModel model, Cmd.none )

                _ ->
                    ( SafeModel model, Cmd.none )

        ToggleTab tab ->
            let
                postToggleCmd =
                    if tab == TextTab then
                        Text.Component.reinitialize_ck_editors model.text_component

                    else
                        Cmd.none
            in
            ( SafeModel { model | selectedTab = tab }, postToggleCmd )

        ClearMessages _ ->
            ( SafeModel { model | successMessage = Nothing }
            , Cmd.none
            )

        TextTagsDecode result ->
            case result of
                Ok tagDict ->
                    ( SafeModel { model | tags = tagDict }, Cmd.none )

                _ ->
                    ( SafeModel model, Cmd.none )

        TextComponentMsg textComponentMsg ->
            Text.Update.update textComponentMsg model
                |> Tuple.mapFirst SafeModel

        TextTranslationMsg textTransMsg ->
            case model.textTranslationsModel of
                Just translationModel ->
                    let
                        ( textTranslationsModel, textTranslationCmd ) =
                            Text.Translations.Update.update TextTranslationMsg textTransMsg translationModel
                    in
                    ( SafeModel { model | textTranslationsModel = Just textTranslationsModel }, textTranslationCmd )

                Nothing ->
                    ( SafeModel model, Cmd.none )


getText :
    Session
    -> Config
    -> Int
    -> Cmd Msg
getText session config textId =
    Api.get
        (Endpoint.text (Config.restApiUrl config) textId [])
        (Session.cred session)
        GotText
        Text.Decode.textDecoder


postText :
    Session
    -> Config
    -> Text
    -> Cmd Msg
postText session config text =
    Api.post
        (Endpoint.createText (Config.restApiUrl config))
        (Session.cred session)
        (Http.jsonBody (Text.Encode.textEncoder text))
        GotTextCreated
        Text.Decode.textCreateRespDecoder


updateText :
    Session
    -> Config
    -> Text
    -> Cmd Msg
updateText session config text =
    case text.id of
        Just textId ->
            Api.put
                (Endpoint.text (Config.restApiUrl config) textId [])
                (Session.cred session)
                (Http.jsonBody (Text.Encode.textEncoder text))
                GotTextUpdated
                Text.Decode.textUpdateRespDecoder

        _ ->
            Cmd.none


deleteText :
    Session
    -> Config
    -> Text.Model.Text
    -> Cmd Msg
deleteText session config text =
    case text.id of
        Just textId ->
            Api.delete
                (Endpoint.text (Config.restApiUrl config) textId [])
                (Session.cred session)
                Http.emptyBody
                GotTextDeleted
                Text.Decode.textDeleteRespDecoder

        _ ->
            Cmd.none


postLock :
    Session
    -> Config
    -> Text.Model.Text
    -> Cmd Msg
postLock session config text =
    case text.id of
        Just textId ->
            Api.post
                (Endpoint.textLock (Config.restApiUrl config) textId)
                (Session.cred session)
                Http.emptyBody
                TextLocked
                Text.Decode.textLockRespDecoder

        _ ->
            Cmd.none


deleteLock :
    Session
    -> Config
    -> Text.Model.Text
    -> Cmd Msg
deleteLock session config text =
    case text.id of
        Just textId ->
            Api.delete
                (Endpoint.textLock (Config.restApiUrl config) textId)
                (Session.cred session)
                Http.emptyBody
                TextUnlocked
                Text.Decode.textLockRespDecoder

        _ ->
            Cmd.none


tagsToDict : List String -> Cmd Msg
tagsToDict tagList =
    Task.attempt
        TextTagsDecode
        (Task.succeed <| Dict.fromList (List.map (\tag -> ( tag, tag )) tagList))



-- DECODE


decodeRespErrors : String -> Result Decode.Error TextsResponseError
decodeRespErrors str =
    Decode.decodeString (Decode.field "errors" (Decode.dict Decode.string)) str



-- VIEW


view : SafeModel -> Document Msg
view (SafeModel model) =
    let
        textViewParams =
            { text = Text.Component.text model.text_component
            , text_component = model.text_component
            , text_translations_model = model.textTranslationsModel
            , text_fields = Text.Component.text_fields model.text_component
            , tags = model.tags
            , selected_tab = model.selectedTab
            , profile = model.profile
            , write_locked = model.writeLocked
            , mode = model.mode
            , text_difficulties = model.textDifficulties
            }

        messages =
            { onToggleEditable = ToggleEditable
            , onTextComponentMsg = TextComponentMsg
            , onDeleteText = SubmittedTextDelete
            , onSubmitText = SubmittedText
            , onUpdateTextAttributes = UpdateTextAttributes
            , onToggleTab = ToggleTab
            , onToggleLock = ToggleLock
            , onAddTagInput = AddTagInput
            , onDeleteTag = DeleteTag
            , onTextTranslationMsg = TextTranslationMsg
            }
    in
    { title = "Create Text"
    , body =
        [ div []
            [ viewMessages (SafeModel model)
            , Text.View.view_text
                textViewParams
                messages
                Shared.answerFeedbackCharacterLimit
            ]
        ]
    }


viewMessages : SafeModel -> Html Msg
viewMessages (SafeModel model) =
    div [ attribute "class" "msgs" ]
        [ div [ attribute "class" "error_msg" ] [ viewMessage model.errorMessage ]
        , div [ attribute "class" "success_msg" ] [ viewMessage model.successMessage ]
        ]


viewMessage : Maybe String -> Html Msg
viewMessage msg =
    let
        msgStr =
            case msg of
                Just str ->
                    String.join " " [ " ", str ]

                _ ->
                    ""
    in
    Html.text msgStr



-- SHARED


save : SafeModel -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> SafeModel -> ( SafeModel, Cmd Msg )
load shared safeModel =
    ( safeModel, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : SafeModel -> Sub Msg
subscriptions (SafeModel model) =
    Sub.batch <|
        [ -- text updates
          Text.Subscriptions.subscriptions TextComponentMsg model

        -- handle clearing messages
        , case model.successMessage of
            Just _ ->
                Time.every 3.0 ClearMessages

            _ ->
                Sub.none

        -- text ckeditor updates
        , ckEditorUpdate UpdateTextCkEditors

        -- handle text delete confirmation
        , confirmation ConfirmedTextDelete
        ]