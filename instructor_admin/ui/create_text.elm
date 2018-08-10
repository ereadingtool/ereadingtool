import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Http
import HttpHelpers exposing (post_with_headers, put_with_headers, delete_with_headers)

import Config exposing (text_api_endpoint, text_api_endpoint)
import Flags

import Text.Model
import Text.Component exposing (TextComponent)
import Text.Field
import Text.Encode

import Views
import Navigation

import Profile
import Instructor.Profile

import Debug
import Json.Decode as Decode
import Json.Encode

import Text.Model exposing (Text, TextDifficulty)
import Text.View

import Navigation
import Text.Decode

import Time

import Text.Update

import Task

import Dict exposing (Dict)

import Text.Subscriptions

import Ports exposing (ckEditor, ckEditorUpdate, clearInputText, confirm, confirmation)

import Text.Create exposing (..)

init : Flags -> (Model, Cmd Msg)
init flags = ({
        flags=flags
      , mode=CreateMode
      , success_msg=Nothing
      , error_msg=Nothing
      , profile=Instructor.Profile.init_profile flags.instructor_profile
      , text_component=Text.Component.emptyTextComponent
      , text_difficulties=[]
      , tags=Dict.fromList []
      , write_locked=False
  }
  , Cmd.batch [
      retrieveTextDifficultyOptions
    , textJSONtoComponent flags.text
    , initializeIntroEditor
    , tagsToDict flags.tags
    ])

tagsToDict : List String -> Cmd Msg
tagsToDict tag_list =
  Task.attempt TextTagsDecode (Task.succeed <| Dict.fromList (List.map (\tag -> (tag, tag)) tag_list))

initializeIntroEditor : Cmd Msg
initializeIntroEditor =
  -- CreateMode, initialize the introduction editor
  Task.attempt (\_-> InitIntroEditor) (Task.succeed Nothing)

textJSONtoComponent : Maybe Json.Encode.Value -> Cmd Msg
textJSONtoComponent text =
  case text of
    Just json -> Task.attempt TextJSONDecode
      (case (Decode.decodeValue Text.Decode.textDecoder json) of
        Ok text -> Task.succeed (Text.Component.init text)
        Err err -> Task.fail err)
    Nothing ->
      Cmd.none

retrieveTextDifficultyOptions : Cmd Msg
retrieveTextDifficultyOptions =
  let
    request = Http.get (String.join "?" [text_api_endpoint, "difficulties=list"]) Text.Decode.textDifficultyDecoder
  in
    Http.send UpdateTextDifficultyOptions request

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
    TextComponentMsg msg ->
      (Text.Update.update msg model)

    SubmitText ->
      let
        text = Text.Component.text model.text_component
      in
        case model.mode of
          ReadOnlyMode write_locker ->
            ({ model | success_msg = Just <| "Text is locked by " ++ write_locker}, Cmd.none)
          EditMode ->
            ({ model | error_msg = Nothing, success_msg = Nothing }, update_text model.flags.csrftoken text)
          CreateMode ->
            ({ model | error_msg = Nothing, success_msg = Nothing }, post_text model.flags.csrftoken text)

    TextJSONDecode result ->
      case result of
        Ok text_component ->
          let
            text = Text.Component.text text_component
          in
            case text.write_locker of
              Just write_locker ->
                case write_locker /= (Instructor.Profile.username model.profile) of
                  True ->
                    ({ model |
                         text_component=text_component
                       , mode=ReadOnlyMode write_locker
                       , error_msg=Just <| "READONLY: text is currently being edited by " ++ write_locker
                       , write_locked=True
                     }, Text.Component.reinitialize_ck_editors text_component)
                  False ->
                    ({ model |
                         text_component=text_component
                       , mode=EditMode
                       , success_msg=Just <| "editing '" ++ text.title ++ "' text"
                       , write_locked=True
                    }, Text.Component.reinitialize_ck_editors text_component)
              Nothing ->
                ({ model |
                     text_component=text_component
                   , mode=EditMode
                   , success_msg=Just <| "editing '" ++ text.title ++ "' text"
                 }, Text.Component.reinitialize_ck_editors text_component)

        Err err -> let _ = Debug.log "text decode error" err in
          ({ model |
              error_msg = (Just <| "Something went wrong loading the text from the server.")
            , success_msg = (Just <| "Editing a new text") }, Cmd.none)

    InitIntroEditor ->
      let
        text_intro_field = Text.Field.intro (Text.Component.text_fields model.text_component)
        intro_field_id = (Text.Field.text_intro_attrs text_intro_field).input_id
      in
        (model, Ports.ckEditor intro_field_id)

    TextTagsDecode result ->
      case result of
        Ok tag_dict ->
          ({ model | tags=tag_dict }, Cmd.none)
        _ -> (model, Cmd.none)

    ClearMessages time ->
      ({ model | success_msg = Nothing }, Cmd.none)

    Submitted (Ok text_create_resp) ->
      let
         text = Text.Component.text model.text_component
      in
         ({ model |
             success_msg = Just <| String.join " " [" created '" ++ text.title ++ "'"]
           , mode=EditMode }, Navigation.load text_create_resp.redirect)

    Updated (Ok text_update_resp) ->
      let
         text = Text.Component.text model.text_component
      in
         ({ model | success_msg = Just <| String.join " " [" saved '" ++ text.title ++ "'"] }, Cmd.none)

    Submitted (Err err) ->
      case err of
        Http.BadStatus resp ->
          case (Text.Decode.decodeRespErrors resp.body) of
            Ok errors ->
              ({ model | text_component = Text.Component.update_text_errors model.text_component errors }, Cmd.none)
            _ -> (model, Cmd.none)

        Http.BadPayload err resp -> let _ = Debug.log "submit text bad payload error" resp.body in
          (model, Cmd.none)

        _ -> (model, Cmd.none)

    Updated (Err err) ->
      case err of
        Http.BadStatus resp -> let _ = Debug.log "update error bad status" resp in
          case (Text.Decode.decodeRespErrors resp.body) of
            Ok errors ->
              ({ model | text_component = Text.Component.update_text_errors model.text_component errors }, Cmd.none)
            _ -> (model, Cmd.none)

        Http.BadPayload err resp -> let _ = Debug.log "update error bad payload" resp in
          (model, Cmd.none)

        _ -> (model, Cmd.none)

    UpdateTextDifficultyOptions (Ok difficulties) ->
      ({ model | text_difficulties = difficulties }, Cmd.none)

    -- handle user-friendly msgs
    UpdateTextDifficultyOptions (Err _) ->
      (model, Cmd.none)

    ToggleEditable text_field editable ->
      let
        (text_component, post_toggle_cmds) = (
          case text_field of
            Title text_title ->
              ( Text.Component.set_title_editable model.text_component editable
              , Text.Component.post_toggle_title)
            Author text_author ->
              ( Text.Component.set_author_editable model.text_component editable
              , Text.Component.post_toggle_author)
            Source text_source ->
              ( Text.Component.set_source_editable model.text_component editable
              , Text.Component.post_toggle_source)
            _ ->
              (model.text_component, \_ -> Cmd.none))
       in
         ({ model | text_component = text_component}, post_toggle_cmds text_component)

    ToggleLock ->
      let
        text = Text.Component.text model.text_component

        lock = post_lock model.flags.csrftoken text
        unlock = delete_lock model.flags.csrftoken text
      in
        (model, if not model.write_locked then lock else unlock)

    TextLocked (Ok text_locked_resp) ->
      ({ model |
        write_locked = (if text_locked_resp.locked then True else False)
      , success_msg =
          Just "text is locked for editing, other instructors can only view the text while it is locked." }, Cmd.none)

    TextUnlocked (Ok text_unlocked_resp) ->
      ({ model |
        write_locked = (if text_unlocked_resp.locked then True else False)
      , success_msg =
          Just "text is unlocked for editing, other instructors can now edit the text." }, Cmd.none)

    TextUnlocked (Err err) ->
      case err of
        Http.BadStatus resp -> let _ = Debug.log "update error bad status" resp in
          case (Text.Decode.decodeRespErrors resp.body) of
            Ok errors ->
              let
                errors_str = String.join " and " (Dict.values errors)
              in
                ({ model | success_msg = Just <| "Error trying to unlock the text: " ++ errors_str }, Cmd.none)
            _ -> (model, Cmd.none)

        Http.BadPayload err resp -> let _ = Debug.log "update error bad payload" resp in
          (model, Cmd.none)

        _ -> (model, Cmd.none)

    TextLocked (Err err) ->
       case err of
        Http.BadStatus resp -> let _ = Debug.log "update error bad status" resp in
          case (Text.Decode.decodeRespErrors resp.body) of
            Ok errors ->
              let
                errors_str = String.join " and " (Dict.values errors)
              in
                ({ model | success_msg = Just <| "Error trying to lock the text: " ++ errors_str }, Cmd.none)
            _ -> (model, Cmd.none)

        Http.BadPayload err resp -> let _ = Debug.log "update error bad payload" resp in
          (model, Cmd.none)

        _ -> (model, Cmd.none)

    UpdateTextAttributes attr_name attr_value ->
      ({ model | text_component = Text.Component.set_text_attribute model.text_component attr_name attr_value }
      , Cmd.none)

    UpdateTextIntro (ck_id, ck_text) ->
      let
        text_intro_attrs =
          Text.Field.text_intro_attrs (Text.Field.intro (Text.Component.text_fields model.text_component))
        text_intro_attrs_id = text_intro_attrs.input_id
      in
        if (ck_id == text_intro_attrs_id) then
          ({ model | text_component =
            Text.Component.set_text_attribute model.text_component "introduction" ck_text }, Cmd.none)
        else
          (model, Cmd.none)

    AddTagInput input_id input ->
      case Dict.member input model.tags of
        True ->
          ({ model | text_component = Text.Component.add_tag model.text_component input }
          , clearInputText input_id)
        _ -> (model, Cmd.none)

    DeleteTag tag ->
      ({ model | text_component = Text.Component.remove_tag model.text_component tag }, Cmd.none)

    DeleteText ->
      (model, confirm "Are you sure you want to delete this text?")

    ConfirmTextDelete confirm ->
      case confirm of
        True ->
          let
            text = Text.Component.text model.text_component
          in
            (model, delete_text model.flags.csrftoken text)
        False ->
          (model, Cmd.none)

    TextDelete (Ok text_delete) -> let _ = Debug.log "text delete" text_delete in
      (model, Navigation.load text_delete.redirect )

    TextDelete (Err err) ->
      case err of
        Http.BadStatus resp -> let _ = Debug.log "delete text error bad status" resp in
          case (Text.Decode.decodeRespErrors resp.body) of
            Ok errors ->
              let
                errors_str = String.join " and " (Dict.values errors)
              in
                ({ model | success_msg = Just <| "Error trying to delete the text: " ++ errors_str }, Cmd.none)
            _ -> (model, Cmd.none)

        Http.BadPayload err resp -> let _ = Debug.log "delete text error bad payload" resp in
          (model, Cmd.none)

        _ -> let _ = Debug.log "delete text error bad payload" err in
          (model, Cmd.none)


post_lock : Flags.CSRFToken -> Text.Model.Text -> Cmd Msg
post_lock csrftoken text =
  case text.id of
    Just text_id ->
      let
        req =
          post_with_headers
            (String.join "" [text_api_endpoint, toString text_id, "/", "lock/"])
            [Http.header "X-CSRFToken" csrftoken]
            Http.emptyBody
            Text.Decode.textLockRespDecoder
      in
        Http.send TextLocked req
    _ -> Cmd.none

delete_lock : Flags.CSRFToken -> Text.Model.Text -> Cmd Msg
delete_lock csrftoken text =
  case text.id of
    Just text_id ->
      let
        req =
          delete_with_headers
            (String.join "" [text_api_endpoint, toString text_id, "/", "lock/"])
            [Http.header "X-CSRFToken" csrftoken]
            Http.emptyBody
            Text.Decode.textLockRespDecoder
      in
        Http.send TextUnlocked req
    _ -> Cmd.none


post_text : Flags.CSRFToken -> Text.Model.Text -> Cmd Msg
post_text csrftoken text =
  let
    encoded_text = Text.Encode.textEncoder text
    req = post_with_headers text_api_endpoint [Http.header "X-CSRFToken" csrftoken] (Http.jsonBody encoded_text)
      <| Text.Decode.textCreateRespDecoder
  in
    Http.send Submitted req

update_text : Flags.CSRFToken -> Text.Model.Text -> Cmd Msg
update_text csrftoken text =
  case text.id of
    Just text_id ->
      let
        encoded_text = Text.Encode.textEncoder text
        req = put_with_headers
          (String.join "" [text_api_endpoint, toString text_id, "/"]) [Http.header "X-CSRFToken" csrftoken]
          (Http.jsonBody encoded_text) <| Text.Decode.textUpdateRespDecoder
      in
        Http.send Updated req
    _ -> Cmd.none

delete_text : Flags.CSRFToken -> Text.Model.Text -> Cmd Msg
delete_text csrftoken text =
  case text.id of
    Just text_id ->
      let
        req = delete_with_headers
          (String.join "" [text_api_endpoint, toString text_id, "/"]) [Http.header "X-CSRFToken" csrftoken]
          (Http.emptyBody) Text.Decode.textDeleteRespDecoder
      in
        Http.send TextDelete req
    _ -> Cmd.none

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [
      -- text updates
      Text.Subscriptions.subscriptions TextComponentMsg model
      -- handle clearing messages
    , (case model.success_msg of
        Just msg -> Time.every (Time.second * 3) ClearMessages
        _ -> Sub.none)
      -- text introduction updates
    , ckEditorUpdate UpdateTextIntro
      -- handle text delete confirmation
    , confirmation ConfirmTextDelete
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
    msg_str = (case msg of
      Just str -> String.join " " [" ", str]
      _ -> "")
  in
    Html.text msg_str

view_msgs : Model -> Html Msg
view_msgs model = div [attribute "class" "msgs"] [
    div [attribute "class" "error_msg" ] [ view_msg model.error_msg ]
  , div [attribute "class" "success_msg"] [ view_msg model.success_msg ]
  ]

view : Model -> Html Msg
view model =
  let
    text_view_params = {
        text=Text.Component.text model.text_component
      , text_component=model.text_component
      , text_fields=Text.Component.text_fields model.text_component
      , tags=model.tags
      , profile=model.profile
      , write_locked=model.write_locked
      , mode=model.mode
      , text_difficulties=model.text_difficulties }
  in
    div [] [
        Views.view_header (Profile.fromInstructorProfile model.profile) Nothing
      , view_msgs model
      , Views.view_preview
      , Text.View.view_text text_view_params
    ]
