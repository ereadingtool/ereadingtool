import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Http
import HttpHelpers exposing (post_with_headers, put_with_headers, delete_with_headers)

import Config exposing (text_api_endpoint, quiz_api_endpoint)
import Flags

import Quiz.Model
import Quiz.Component exposing (QuizComponent)
import Quiz.Encode

import Views
import Navigation

import Profile
import Instructor.Profile

import Debug
import Json.Decode as Decode
import Json.Encode

import Text.Model exposing (Text, TextDifficulty)
import Quiz.Model
import Quiz.View

import Navigation
import Quiz.Decode

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
      , quiz_component=Quiz.Component.emptyQuizComponent
      , text_difficulties=[]
      , tags=Dict.fromList []
      , write_locked=False
  }, Cmd.batch [ retrieveTextDifficultyOptions, (quizJSONtoComponent flags.text), tagsToDict flags.tags ])

textDifficultyDecoder : Decode.Decoder (List TextDifficulty)
textDifficultyDecoder = Decode.keyValuePairs Decode.string

tagsToDict : List String -> Cmd Msg
tagsToDict tag_list =
  Task.attempt QuizTagsDecode (Task.succeed <| Dict.fromList (List.map (\tag -> (tag, tag)) tag_list))

quizJSONtoComponent : Maybe Json.Encode.Value -> Cmd Msg
quizJSONtoComponent quiz =
  case quiz of
      Just json -> Task.attempt QuizJSONDecode
        (case (Decode.decodeValue Quiz.Decode.quizDecoder json) of
           Ok quiz -> Task.succeed (Quiz.Component.init quiz)
           Err err -> Task.fail err)
      _ -> Cmd.none

retrieveTextDifficultyOptions : Cmd Msg
retrieveTextDifficultyOptions =
  let request = Http.get (String.join "?" [text_api_endpoint, "difficulties=list"]) textDifficultyDecoder
  in Http.send UpdateTextDifficultyOptions request

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
    TextComponentMsg msg ->
      (Text.Update.update msg model)

    SubmitQuiz ->
      let
        quiz = Quiz.Component.quiz model.quiz_component
      in
        case model.mode of
          ReadOnlyMode write_locker ->
            ({ model | success_msg = Just <| "Quiz is locked by " ++ write_locker}, Cmd.none)
          EditMode ->
            ({ model | error_msg = Nothing, success_msg = Nothing }, update_quiz model.flags.csrftoken quiz)
          CreateMode ->
            ({ model | error_msg = Nothing, success_msg = Nothing }, post_quiz model.flags.csrftoken quiz)

    QuizJSONDecode result ->
      case result of
        Ok quiz_comp ->
          let
            quiz_component = (Quiz.Component.set_intro_editable quiz_comp True)
            quiz = Quiz.Component.quiz quiz_component
          in
            case quiz.write_locker of
              Just write_locker ->
                case write_locker /= (Instructor.Profile.username model.profile) of
                  True ->
                    ({ model |
                         quiz_component=quiz_component
                       , mode=ReadOnlyMode write_locker
                       , error_msg=Just <| "READONLY: quiz is currently being edited by " ++ write_locker
                       , write_locked=True
                     }, Quiz.Component.reinitialize_ck_editors quiz_component)
                  False ->
                    ({ model |
                         quiz_component=quiz_component
                       , mode=EditMode
                       , success_msg=Just <| "editing '" ++ quiz.title ++ "' quiz"
                       , write_locked=True
                    }, Quiz.Component.reinitialize_ck_editors quiz_component)
              Nothing ->
                ({ model |
                     quiz_component=quiz_component
                   , mode=EditMode
                   , success_msg=Just <| "editing '" ++ quiz.title ++ "' quiz"
                 }, Quiz.Component.reinitialize_ck_editors quiz_component)

        Err err -> let _ = Debug.log "quiz decode error" err in
          ({ model |
              error_msg = (Just <| "Something went wrong loading the quiz from the server.")
            , success_msg = (Just <| "Editing a new quiz") }, Cmd.none)

    QuizTagsDecode result ->
      case result of
        Ok tag_dict ->
          ({ model | tags=tag_dict }, Cmd.none)
        _ -> (model, Cmd.none)

    ClearMessages time ->
      ({ model | success_msg = Nothing }, Cmd.none)

    Submitted (Ok quiz_create_resp) ->
      let
         quiz = Quiz.Component.quiz model.quiz_component
      in
         ({ model |
             success_msg = Just <| String.join " " [" created '" ++ quiz.title ++ "'"]
           , mode=EditMode }, Navigation.load quiz_create_resp.redirect)

    Updated (Ok quiz_update_resp) ->
      let
         quiz = Quiz.Component.quiz model.quiz_component
      in
         ({ model | success_msg = Just <| String.join " " [" saved '" ++ quiz.title ++ "'"] }, Cmd.none)

    Submitted (Err err) ->
      case err of
        Http.BadStatus resp ->
          case (Quiz.Decode.decodeRespErrors resp.body) of
            Ok errors ->
              ({ model | quiz_component = Quiz.Component.update_quiz_errors model.quiz_component errors }, Cmd.none)
            _ -> (model, Cmd.none)

        Http.BadPayload err resp -> let _ = Debug.log "submit quiz bad payload error" resp.body in
          (model, Cmd.none)

        _ -> (model, Cmd.none)

    Updated (Err err) ->
      case err of
        Http.BadStatus resp -> let _ = Debug.log "update error bad status" resp in
          case (Quiz.Decode.decodeRespErrors resp.body) of
            Ok errors ->
              ({ model | quiz_component = Quiz.Component.update_quiz_errors model.quiz_component errors }, Cmd.none)
            _ -> (model, Cmd.none)

        Http.BadPayload err resp -> let _ = Debug.log "update error bad payload" resp in
          (model, Cmd.none)

        _ -> (model, Cmd.none)

    UpdateTextDifficultyOptions (Ok difficulties) ->
      ({ model | text_difficulties = difficulties }, Cmd.none)

    -- handle user-friendly msgs
    UpdateTextDifficultyOptions (Err _) ->
      (model, Cmd.none)

    ToggleEditable quiz_field editable ->
      let
        (quiz_component, post_toggle_cmds) = (
          case quiz_field of
            Title quiz_title ->
              ( Quiz.Component.set_title_editable model.quiz_component editable
              , Quiz.Component.post_toggle_title)
            Intro quiz_intro ->
              ( Quiz.Component.set_intro_editable model.quiz_component editable
              , Quiz.Component.post_toggle_intro)
            Author text_author -> let _ = Debug.log "editable" editable in
              ( Quiz.Component.set_author_editable model.quiz_component editable
              , Quiz.Component.post_toggle_author)
            Source text_source ->
              ( Quiz.Component.set_source_editable model.quiz_component editable
              , Quiz.Component.post_toggle_source)
            _ ->
              (model.quiz_component, \_ -> Cmd.none))
       in
         ({ model | quiz_component = quiz_component}, post_toggle_cmds quiz_component)

    ToggleLock ->
      let
        quiz = Quiz.Component.quiz model.quiz_component

        lock = post_lock model.flags.csrftoken quiz
        unlock = delete_lock model.flags.csrftoken quiz
      in
        (model, if not model.write_locked then lock else unlock)

    QuizLocked (Ok quiz_locked_resp) ->
      ({ model |
        write_locked = (if quiz_locked_resp.locked then True else False)
      , success_msg =
          Just "quiz is locked for editing, other instructors can only view the quiz while it is locked." }, Cmd.none)

    QuizUnlocked (Ok quiz_unlocked_resp) ->
      ({ model |
        write_locked = (if quiz_unlocked_resp.locked then True else False)
      , success_msg =
          Just "quiz is unlocked for editing, other instructors can now edit the quiz." }, Cmd.none)

    QuizUnlocked (Err err) ->
      case err of
        Http.BadStatus resp -> let _ = Debug.log "update error bad status" resp in
          case (Quiz.Decode.decodeRespErrors resp.body) of
            Ok errors ->
              let
                errors_str = String.join " and " (Dict.values errors)
              in
                ({ model | success_msg = Just <| "Error trying to unlock the quiz: " ++ errors_str }, Cmd.none)
            _ -> (model, Cmd.none)

        Http.BadPayload err resp -> let _ = Debug.log "update error bad payload" resp in
          (model, Cmd.none)

        _ -> (model, Cmd.none)

    QuizLocked (Err err) ->
       case err of
        Http.BadStatus resp -> let _ = Debug.log "update error bad status" resp in
          case (Quiz.Decode.decodeRespErrors resp.body) of
            Ok errors ->
              let
                errors_str = String.join " and " (Dict.values errors)
              in
                ({ model | success_msg = Just <| "Error trying to lock the quiz: " ++ errors_str }, Cmd.none)
            _ -> (model, Cmd.none)

        Http.BadPayload err resp -> let _ = Debug.log "update error bad payload" resp in
          (model, Cmd.none)

        _ -> (model, Cmd.none)

    UpdateQuizAttributes attr_name attr_value ->
      ({ model | quiz_component = Quiz.Component.set_quiz_attribute model.quiz_component attr_name attr_value }
      , Cmd.none)

    UpdateQuizIntro (ck_id, ck_text) ->
      case ck_id of
       "quiz_introduction" ->
         ({ model | quiz_component =
           Quiz.Component.set_quiz_attribute model.quiz_component "introduction" ck_text }, Cmd.none)
       _ -> (model, Cmd.none)

    AddTagInput input_id input ->
      case Dict.member input model.tags of
        True ->
          ({ model | quiz_component = Quiz.Component.add_tag model.quiz_component input }
          , clearInputText input_id)
        _ -> (model, Cmd.none)

    DeleteTag tag ->
      ({ model | quiz_component = Quiz.Component.remove_tag model.quiz_component tag }, Cmd.none)

    DeleteQuiz ->
      (model, confirm "Are you sure you want to delete this quiz?")

    ConfirmQuizDelete confirm ->
      case confirm of
        True ->
          let
            quiz = Quiz.Component.quiz model.quiz_component
          in
            (model, delete_quiz model.flags.csrftoken quiz)
        False ->
          (model, Cmd.none)

    QuizDelete (Ok quiz_delete) -> let _ = Debug.log "quiz delete" quiz_delete in
      (model, Navigation.load quiz_delete.redirect )

    QuizDelete (Err err) ->
      case err of
        Http.BadStatus resp -> let _ = Debug.log "delete quiz error bad status" resp in
          case (Quiz.Decode.decodeRespErrors resp.body) of
            Ok errors ->
              let
                errors_str = String.join " and " (Dict.values errors)
              in
                ({ model | success_msg = Just <| "Error trying to delete the quiz: " ++ errors_str }, Cmd.none)
            _ -> (model, Cmd.none)

        Http.BadPayload err resp -> let _ = Debug.log "delete quiz error bad payload" resp in
          (model, Cmd.none)

        _ -> let _ = Debug.log "delete quiz error bad payload" err in
          (model, Cmd.none)


post_lock : Flags.CSRFToken -> Quiz.Model.Quiz -> Cmd Msg
post_lock csrftoken quiz =
  case quiz.id of
    Just quiz_id ->
      let
        req =
          post_with_headers
            (String.join "" [quiz_api_endpoint, toString quiz_id, "/", "lock/"])
            [Http.header "X-CSRFToken" csrftoken]
            Http.emptyBody
            Quiz.Decode.quizLockRespDecoder
      in
        Http.send QuizLocked req
    _ -> Cmd.none

delete_lock : Flags.CSRFToken -> Quiz.Model.Quiz -> Cmd Msg
delete_lock csrftoken quiz =
  case quiz.id of
    Just quiz_id ->
      let
        req =
          delete_with_headers
            (String.join "" [quiz_api_endpoint, toString quiz_id, "/", "lock/"])
            [Http.header "X-CSRFToken" csrftoken]
            Http.emptyBody
            Quiz.Decode.quizLockRespDecoder
      in
        Http.send QuizUnlocked req
    _ -> Cmd.none


post_quiz : Flags.CSRFToken -> Quiz.Model.Quiz -> Cmd Msg
post_quiz csrftoken quiz =
  let
    encoded_quiz = Quiz.Encode.quizEncoder quiz
    req = post_with_headers quiz_api_endpoint [Http.header "X-CSRFToken" csrftoken] (Http.jsonBody encoded_quiz)
      <| Quiz.Decode.quizCreateRespDecoder
  in
    Http.send Submitted req

update_quiz : Flags.CSRFToken -> Quiz.Model.Quiz -> Cmd Msg
update_quiz csrftoken quiz =
  case quiz.id of
    Just quiz_id ->
      let
        encoded_quiz = Quiz.Encode.quizEncoder quiz
        req = put_with_headers
          (String.join "" [quiz_api_endpoint, toString quiz_id, "/"]) [Http.header "X-CSRFToken" csrftoken]
          (Http.jsonBody encoded_quiz) <| Quiz.Decode.quizUpdateRespDecoder
      in
        Http.send Updated req
    _ -> Cmd.none

delete_quiz : Flags.CSRFToken -> Quiz.Model.Quiz -> Cmd Msg
delete_quiz csrftoken quiz =
  case quiz.id of
    Just quiz_id ->
      let
        req = delete_with_headers
          (String.join "" [quiz_api_endpoint, toString quiz_id, "/"]) [Http.header "X-CSRFToken" csrftoken]
          (Http.emptyBody) Quiz.Decode.quizDeleteRespDecoder
      in
        Http.send QuizDelete req
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
      -- quiz introduction updates
    , ckEditorUpdate UpdateQuizIntro
      -- handle quiz delete confirmation
    , confirmation ConfirmQuizDelete
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
    quiz_view_params = {
        quiz=Quiz.Component.quiz model.quiz_component
      , quiz_component=model.quiz_component
      , quiz_fields=Quiz.Component.quiz_fields model.quiz_component
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
      , Quiz.View.view_quiz quiz_view_params
    ]
