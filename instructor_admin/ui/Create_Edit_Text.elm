module Create_Edit_Text exposing
    ( deleteLock
    , deleteText
    , init
    , main
    , postLock
    , postText
    , retrieveTextDifficultyOptions
    , subscriptions
    , tagsToDict
    , textJSONtoComponent
    , update
    , updateText
    , view
    , view_msg
    , view_msgs
    )

import Admin.Text
import Debug
import Dict
import Flags
import Html exposing (..)
import Html.Attributes exposing (attribute)
import Http
import HttpHelpers exposing (delete_with_headers, post_with_headers, put_with_headers)
import Instructor.Profile
import Json.Decode as Decode
import Json.Encode
import Menu.Items
import Navigation
import Ports exposing (ckEditorUpdate, clearInputText, confirm, confirmation)
import Task
import Text.Component
import Text.Create exposing (..)
import Text.Decode
import Text.Encode
import Text.Field
import Text.Model exposing (Text)
import Text.Subscriptions
import Text.Translations.Model
import Text.Translations.Subscriptions
import Text.Translations.Update
import Text.Update
import Text.View
import Time
import User.Profile
import Views


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        textApiEndpoint =
            Admin.Text.TextAPIEndpoint (Admin.Text.URL flags.text_endpoint_url)
    in
    ( { flags = flags
      , mode = CreateMode
      , success_msg = Nothing
      , error_msg = Nothing
      , profile = Instructor.Profile.initProfile flags.instructor_profile
      , menu_items = Menu.Items.initMenuItems flags
      , text_component = Text.Component.emptyTextComponent
      , text_api_endpoint = textApiEndpoint
      , text_difficulties = []
      , text_translations_model = Nothing
      , tags = Dict.fromList []
      , selected_tab = TextTab
      , write_locked = False
      }
    , Cmd.batch
        [ retrieveTextDifficultyOptions textApiEndpoint
        , textJSONtoComponent flags.text
        , tagsToDict flags.tags
        ]
    )


tagsToDict : List String -> Cmd Msg
tagsToDict tagList =
    Task.attempt TextTagsDecode (Task.succeed <| Dict.fromList (List.map (\tag -> ( tag, tag )) tagList))


textJSONtoComponent : Maybe Json.Encode.Value -> Cmd Msg
textJSONtoComponent text =
    case text of
        Just json ->
            Task.attempt TextJSONDecode
                (case Decode.decodeValue Text.Decode.textDecoder json of
                    Ok text ->
                        Task.succeed (Text.Component.init text)

                    Err err ->
                        Task.fail err
                )

        Nothing ->
            -- CreateMode, initialize the text field editors
            Task.attempt (\_ -> InitTextFieldEditors) (Task.succeed Nothing)


retrieveTextDifficultyOptions : Admin.Text.TextAPIEndpoint -> Cmd Msg
retrieveTextDifficultyOptions textApiEndpoint =
    let
        textApiEndpointUrl =
            Admin.Text.textEndpointToString textApiEndpoint

        request =
            Http.get (String.join "?" [ textApiEndpointUrl, "difficulties=list" ]) Text.Decode.textDifficultiesDecoder
    in
    Http.send UpdateTextDifficultyOptions request


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TextComponentMsg msg ->
            Text.Update.update msg model

        Text.Create.TextTranslationMsg msg ->
            case model.text_translations_model of
                Just translationModel ->
                    let
                        ( textTranslationsModel, textTranslationCmd ) =
                            Text.Translations.Update.update TextTranslationMsg msg translationModel
                    in
                    ( { model | text_translations_model = Just textTranslationsModel }, textTranslationCmd )

                Nothing ->
                    ( model, Cmd.none )

        SubmitText ->
            let
                text =
                    Text.Component.text model.text_component
            in
            case model.mode of
                ReadOnlyMode writeLocker ->
                    ( { model | success_msg = Just <| "Text is locked by " ++ writeLocker }, Cmd.none )

                EditMode ->
                    ( { model | error_msg = Nothing, success_msg = Nothing }
                    , updateText model.flags.csrftoken model.text_api_endpoint text
                    )

                CreateMode ->
                    ( { model | error_msg = Nothing, success_msg = Nothing }
                    , postText model.flags.csrftoken model.text_api_endpoint text
                    )

        TextJSONDecode result ->
            case result of
                Ok textComponent ->
                    let
                        text =
                            Text.Component.text textComponent
                    in
                    case text.write_locker of
                        Just writeLocker ->
                            case writeLocker /= Instructor.Profile.usernameToString (Instructor.Profile.username model.profile) of
                                True ->
                                    ( { model
                                        | text_component = textComponent
                                        , mode = ReadOnlyMode writeLocker
                                        , error_msg = Just <| "READONLY: text is currently being edited by " ++ writeLocker
                                        , write_locked = True
                                      }
                                    , Text.Component.reinitialize_ck_editors textComponent
                                    )

                                False ->
                                    ( { model
                                        | text_component = textComponent
                                        , mode = EditMode
                                        , success_msg = Just <| "editing '" ++ text.title ++ "' text"
                                        , write_locked = True
                                      }
                                    , Cmd.batch
                                        [ Text.Component.reinitialize_ck_editors textComponent
                                        , Text.Translations.Update.retrieveTextWords TextTranslationMsg model.text_api_endpoint text.id
                                        ]
                                    )

                        Nothing ->
                            case text.id of
                                Just id ->
                                    ( { model
                                        | text_component = textComponent
                                        , mode = EditMode
                                        , text_translations_model =
                                            Just (Text.Translations.Model.init model.flags.translation_flags id text)
                                        , success_msg = Just <| "editing '" ++ text.title ++ "' text"
                                      }
                                    , Cmd.batch
                                        [ Text.Component.reinitialize_ck_editors textComponent
                                        , Text.Translations.Update.retrieveTextWords TextTranslationMsg model.text_api_endpoint text.id
                                        ]
                                    )

                                Nothing ->
                                    ( { model
                                        | text_component = textComponent
                                        , mode = EditMode
                                        , error_msg = Just <| "Something went wrong: no valid text id"
                                      }
                                    , Text.Component.reinitialize_ck_editors textComponent
                                    )

                Err err ->
                    let
                        _ =
                            Debug.log "text decode error" err
                    in
                    ( { model
                        | error_msg = Just <| "Something went wrong loading the text from the server."
                        , success_msg = Just <| "Editing a new text"
                      }
                    , Cmd.none
                    )

        InitTextFieldEditors ->
            ( model, Text.Component.initialize_text_field_ck_editors model.text_component )

        TextTagsDecode result ->
            case result of
                Ok tag_dict ->
                    ( { model | tags = tag_dict }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ClearMessages time ->
            ( { model | success_msg = Nothing }, Cmd.none )

        Submitted (Ok textCreateResp) ->
            let
                text =
                    Text.Component.text model.text_component
            in
            ( { model
                | success_msg = Just <| String.join " " [ " created '" ++ text.title ++ "'" ]
                , mode = EditMode
              }
            , Navigation.load textCreateResp.redirect
            )

        Updated (Ok textUpdateResp) ->
            let
                text =
                    Text.Component.text model.text_component
            in
            ( { model | success_msg = Just <| String.join " " [ " saved '" ++ text.title ++ "'" ] }, Cmd.none )

        Submitted (Err err) ->
            case err of
                Http.BadStatus resp ->
                    case Text.Decode.decodeRespErrors resp.body of
                        Ok errors ->
                            ( { model | text_component = Text.Component.update_text_errors model.text_component errors }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                Http.BadPayload err resp ->
                    let
                        _ =
                            Debug.log "submit text bad payload error" resp.body
                    in
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Updated (Err err) ->
            case err of
                Http.BadStatus resp ->
                    let
                        _ =
                            Debug.log "update error bad status" resp
                    in
                    case Text.Decode.decodeRespErrors resp.body of
                        Ok errors ->
                            ( { model | text_component = Text.Component.update_text_errors model.text_component errors }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                Http.BadPayload err resp ->
                    let
                        _ =
                            Debug.log "update error bad payload" resp
                    in
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        UpdateTextDifficultyOptions (Ok difficulties) ->
            ( { model | text_difficulties = difficulties }, Cmd.none )

        -- handle user-friendly msgs
        UpdateTextDifficultyOptions (Err _) ->
            ( model, Cmd.none )

        ToggleEditable textField editable ->
            let
                ( textComponent, postToggleCmds ) =
                    case textField of
                        Title textTitle ->
                            ( Text.Component.set_title_editable model.text_component editable
                            , Text.Component.post_toggle_title
                            )

                        Author textAuthor ->
                            ( Text.Component.set_author_editable model.text_component editable
                            , Text.Component.post_toggle_author
                            )

                        Source textSource ->
                            ( Text.Component.set_source_editable model.text_component editable
                            , Text.Component.post_toggle_source
                            )

                        _ ->
                            ( model.text_component, \_ -> Cmd.none )
            in
            ( { model | text_component = textComponent }, postToggleCmds textComponent )

        ToggleLock ->
            let
                text =
                    Text.Component.text model.text_component

                lock =
                    postLock model.flags.csrftoken model.text_api_endpoint text

                unlock =
                    deleteLock model.flags.csrftoken model.text_api_endpoint text
            in
            ( model
            , if not model.write_locked then
                lock

              else
                unlock
            )

        TextLocked (Ok textLockedResp) ->
            ( { model
                | write_locked =
                    if textLockedResp.locked then
                        True

                    else
                        False
                , success_msg =
                    Just "text is locked for editing, other instructors can only view the text while it is locked."
              }
            , Cmd.none
            )

        TextUnlocked (Ok textUnlockedResp) ->
            ( { model
                | write_locked =
                    if textUnlockedResp.locked then
                        True

                    else
                        False
                , success_msg =
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
                    case Text.Decode.decodeRespErrors resp.body of
                        Ok errors ->
                            let
                                errors_str =
                                    String.join " and " (Dict.values errors)
                            in
                            ( { model | success_msg = Just <| "Error trying to unlock the text: " ++ errors_str }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                Http.BadPayload err resp ->
                    let
                        _ =
                            Debug.log "update error bad payload" resp
                    in
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        TextLocked (Err err) ->
            case err of
                Http.BadStatus resp ->
                    let
                        _ =
                            Debug.log "update error bad status" resp
                    in
                    case Text.Decode.decodeRespErrors resp.body of
                        Ok errors ->
                            let
                                errors_str =
                                    String.join " and " (Dict.values errors)
                            in
                            ( { model | success_msg = Just <| "Error trying to lock the text: " ++ errors_str }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                Http.BadPayload err resp ->
                    let
                        _ =
                            Debug.log "update error bad payload" resp
                    in
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        UpdateTextAttributes attrName attrValue ->
            ( { model | text_component = Text.Component.set_text_attribute model.text_component attrName attrValue }
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
                ( { model | text_component = Text.Component.set_text_attribute model.text_component "introduction" ckText }
                , Cmd.none
                )

            else if ckId == textConclusionInputId then
                ( { model | text_component = Text.Component.set_text_attribute model.text_component "conclusion" ckText }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        AddTagInput inputId input ->
            case Dict.member input model.tags of
                True ->
                    ( { model | text_component = Text.Component.add_tag model.text_component input }
                    , clearInputText inputId
                    )

                _ ->
                    ( model, Cmd.none )

        DeleteTag tag ->
            ( { model | text_component = Text.Component.remove_tag model.text_component tag }, Cmd.none )

        DeleteText ->
            ( model, confirm "Are you sure you want to delete this text?" )

        ConfirmTextDelete confirm ->
            case confirm of
                True ->
                    let
                        text =
                            Text.Component.text model.text_component
                    in
                    ( model, deleteText model.flags.csrftoken model.text_api_endpoint text )

                False ->
                    ( model, Cmd.none )

        TextDelete (Ok textDelete) ->
            let
                _ =
                    Debug.log "text delete" textDelete
            in
            ( model, Navigation.load textDelete.redirect )

        TextDelete (Err err) ->
            case err of
                Http.BadStatus resp ->
                    let
                        _ =
                            Debug.log "delete text error bad status" resp
                    in
                    case Text.Decode.decodeRespErrors resp.body of
                        Ok errors ->
                            let
                                errorsStr =
                                    String.join " and " (Dict.values errors)
                            in
                            ( { model | success_msg = Just <| "Error trying to delete the text: " ++ errorsStr }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                Http.BadPayload err resp ->
                    let
                        _ =
                            Debug.log "delete text error bad payload" resp
                    in
                    ( model, Cmd.none )

                _ ->
                    let
                        _ =
                            Debug.log "delete text error bad payload" err
                    in
                    ( model, Cmd.none )

        ToggleTab tab ->
            let
                postToggleCmd =
                    case tab == TextTab of
                        True ->
                            Text.Component.reinitialize_ck_editors model.text_component

                        False ->
                            Cmd.none
            in
            ( { model | selected_tab = tab }, postToggleCmd )

        LogOut msg ->
            ( model, Instructor.Profile.logout model.profile model.flags.csrftoken LoggedOut )

        LoggedOut (Ok logoutResp) ->
            ( model, Ports.redirect logoutResp.redirect )

        LoggedOut (Err err) ->
            ( model, Cmd.none )


postLock : Flags.CSRFToken -> Admin.Text.TextAPIEndpoint -> Text.Model.Text -> Cmd Msg
postLock csrftoken textApiEndpoint text =
    case text.id of
        Just textId ->
            let
                textApiEndpointUrl =
                    Admin.Text.textEndpointToString textApiEndpoint

                req =
                    post_with_headers
                        (String.join "" [ textApiEndpointUrl, String.fromInt textId, "/", "lock/" ])
                        [ Http.header "X-CSRFToken" csrftoken ]
                        Http.emptyBody
                        Text.Decode.textLockRespDecoder
            in
            Http.send TextLocked req

        _ ->
            Cmd.none


deleteLock : Flags.CSRFToken -> Admin.Text.TextAPIEndpoint -> Text.Model.Text -> Cmd Msg
deleteLock csrftoken textApiEndpoint text =
    case text.id of
        Just textId ->
            let
                textApiEndpointUrl =
                    Admin.Text.textEndpointToString textApiEndpoint

                req =
                    delete_with_headers
                        (String.join "" [ textApiEndpointUrl, String.fromInt textId, "/", "lock/" ])
                        [ Http.header "X-CSRFToken" csrftoken ]
                        Http.emptyBody
                        Text.Decode.textLockRespDecoder
            in
            Http.send TextUnlocked req

        _ ->
            Cmd.none


postText : Flags.CSRFToken -> Admin.Text.TextAPIEndpoint -> Text -> Cmd Msg
postText csrftoken textApiEndpoint text =
    let
        textApiEndpointUrl =
            Admin.Text.textEndpointToString textApiEndpoint

        encoded_text =
            Text.Encode.textEncoder text

        req =
            post_with_headers textApiEndpointUrl [ Http.header "X-CSRFToken" csrftoken ] (Http.jsonBody encoded_text) <|
                Text.Decode.textCreateRespDecoder
    in
    Http.send Submitted req


updateText : Flags.CSRFToken -> Admin.Text.TextAPIEndpoint -> Text -> Cmd Msg
updateText csrftoken textApiEndpoint text =
    case text.id of
        Just textId ->
            let
                textApiEndpointUrl =
                    Admin.Text.textEndpointToString textApiEndpoint

                encodedText =
                    Text.Encode.textEncoder text

                req =
                    put_with_headers
                        (String.join "" [ textApiEndpointUrl, String.fromInt textId, "/" ])
                        [ Http.header "X-CSRFToken" csrftoken ]
                        (Http.jsonBody encodedText)
                    <|
                        Text.Decode.textUpdateRespDecoder
            in
            Http.send Updated req

        _ ->
            Cmd.none


deleteText : Flags.CSRFToken -> Admin.Text.TextAPIEndpoint -> Text.Model.Text -> Cmd Msg
deleteText csrftoken textApiEndpoint text =
    case text.id of
        Just textId ->
            let
                textApiEndpointUrl =
                    Admin.Text.textEndpointToString textApiEndpoint

                req =
                    delete_with_headers
                        (String.join "" [ textApiEndpointUrl, String.fromInt textId, "/" ])
                        [ Http.header "X-CSRFToken" csrftoken ]
                        Http.emptyBody
                        Text.Decode.textDeleteRespDecoder
            in
            Http.send TextDelete req

        _ ->
            Cmd.none


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch <|
        [ -- text updates
          Text.Subscriptions.subscriptions TextComponentMsg model

        -- handle clearing messages
        , case model.success_msg of
            Just msg ->
                Time.every (Time.second * 3) ClearMessages

            _ ->
                Sub.none

        -- text ckeditor updates
        , ckEditorUpdate UpdateTextCkEditors

        -- handle text delete confirmation
        , confirmation ConfirmTextDelete
        ]
            ++ [ case model.text_translations_model of
                    Just translationModel ->
                        Text.Translations.Subscriptions.subscriptions TextTranslationMsg translationModel

                    Nothing ->
                        Sub.none
               ]


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , subscriptions = subscriptions
        , update = update
        }


view_msg : Maybe String -> Html Msg
view_msg msg =
    let
        msgStr =
            case msg of
                Just str ->
                    String.join " " [ " ", str ]

                _ ->
                    ""
    in
    Html.text msgStr


view_msgs : Model -> Html Msg
view_msgs model =
    div [ attribute "class" "msgs" ]
        [ div [ attribute "class" "error_msg" ] [ view_msg model.error_msg ]
        , div [ attribute "class" "success_msg" ] [ view_msg model.success_msg ]
        ]


view : Model -> Html Msg
view model =
    let
        textViewParams =
            { text = Text.Component.text model.text_component
            , text_component = model.text_component
            , text_translations_model = model.text_translations_model
            , text_translation_msg = TextTranslationMsg
            , text_fields = Text.Component.text_fields model.text_component
            , tags = model.tags
            , selected_tab = model.selected_tab
            , profile = model.profile
            , write_locked = model.write_locked
            , mode = model.mode
            , text_difficulties = model.text_difficulties
            }
    in
    div []
        [ Views.view_authed_header (User.Profile.fromInstructorProfile model.profile) model.menu_items Text.Create.LogOut
        , view_msgs model
        , Text.View.view_text textViewParams model.flags.answer_feedback_limit
        ]
