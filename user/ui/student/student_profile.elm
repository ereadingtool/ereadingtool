import Html exposing (Html, div, span)
import Html.Attributes exposing (class, classList, attribute)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Http exposing (..)
import HttpHelpers

import Json.Encode
import Json.Decode
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)


import Dict exposing (Dict)

import Profile

import Text.Reading.Model exposing (TextReading, TextReadingScore)

import Student.Profile.Model exposing (StudentProfile)
import Student.Profile.Encode

import Config
import Views
import Flags

import Ports

import Menu.Msg as MenuMsg
import Menu.Logout

import HtmlParser
import HtmlParser.Util


-- UPDATE
type Msg =
    RetrieveStudentProfile (Result Error StudentProfile)
  -- preferred difficulty
  | UpdateDifficulty String
  -- username
  | ToggleUsernameUpdate
  | ValidUsername (Result Error UsernameUpdate)
  | UpdateUsername String
  | SubmitUsernameUpdate
  | CancelUsernameUpdate
  -- profile update submission
  | Submitted (Result Error StudentProfile)
  -- site-wide messages
  | Logout MenuMsg.Msg
  | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)

type alias Flags = Flags.Flags {}

type alias UsernameUpdate = { username: String, valid: Maybe Bool, msg: Maybe String }

type alias Model = {
    flags : Flags
  , profile : StudentProfile
  , editing : Dict String Bool
  , err_str : String
  , username_update : UsernameUpdate
  , errors : Dict String String }

username_valid_encode : String -> Json.Encode.Value
username_valid_encode username =
  Json.Encode.object [("username", Json.Encode.string username)]

username_valid_decoder : Json.Decode.Decoder UsernameUpdate
username_valid_decoder =
  decode UsernameUpdate
    |> required "username" Json.Decode.string
    |> required "valid" (Json.Decode.nullable Json.Decode.bool)
    |> required "msg" (Json.Decode.nullable Json.Decode.string)

validate_username : Flags.CSRFToken -> String -> Cmd Msg
validate_username csrftoken username =
  let
    req =
      HttpHelpers.post_with_headers
       Config.username_validation_api_endpoint
       [Http.header "X-CSRFToken" csrftoken]
       (Http.jsonBody (username_valid_encode username)) username_valid_decoder
  in
    Http.send ValidUsername req

put_profile : Flags.CSRFToken -> Student.Profile.Model.StudentProfile -> Cmd Msg
put_profile csrftoken student_profile =
  case Student.Profile.Model.studentID student_profile of
    Just id ->
      let
        encoded_profile = Student.Profile.Encode.profileEncoder student_profile
        req =
          HttpHelpers.put_with_headers
           (Student.Profile.Model.studentUpdateURI id)
           [Http.header "X-CSRFToken" csrftoken]
           (Http.jsonBody encoded_profile) Student.Profile.Model.studentProfileDecoder
      in
        Http.send Submitted req
    Nothing ->
      Cmd.none

init : Flags -> (Model, Cmd Msg)
init flags = ({
    flags = flags
  , profile = Student.Profile.Model.emptyStudentProfile
  , editing = Dict.fromList []
  , username_update = {username = "", valid = Nothing, msg = Nothing}
  , err_str = "", errors = Dict.fromList [] }, Profile.retrieve_student_profile RetrieveStudentProfile flags.profile_id)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

toggle_username_update : Model -> Model
toggle_username_update model =
  { model | editing =
      (if Dict.member "username" model.editing then
        Dict.remove "username" model.editing
       else Dict.insert "username" True model.editing) }

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  RetrieveStudentProfile (Ok profile) ->
    let
      username_update = model.username_update
      new_username_update = { username_update | username = Student.Profile.Model.studentUserName profile }
    in
      ({ model | profile = profile, username_update = new_username_update }, Cmd.none)

  -- handle user-friendly msgs
  RetrieveStudentProfile (Err err) ->
    ({ model | err_str = toString err }, Cmd.none)

  UpdateUsername value ->
    let
      username_update = model.username_update
      new_username_update = { username_update | username = value }
    in
      ({ model | username_update = new_username_update }, validate_username model.flags.csrftoken value)

  ValidUsername (Ok username_update) ->
    ({ model | username_update = username_update }, Cmd.none)

  ValidUsername (Err err) ->
    case err of
      Http.BadStatus resp ->
        case (Json.Decode.decodeString (Json.Decode.dict Json.Decode.string) resp.body) of
          Ok errors ->
            ({ model | errors = errors }, Cmd.none)
          _ ->
            (model, Cmd.none)

      Http.BadPayload err resp -> let _ = Debug.log "bad payload" err in
        (model, Cmd.none)

      _ ->
        (model, Cmd.none)

  UpdateDifficulty difficulty ->
    let
      new_difficulty_preference = (difficulty, difficulty)
      new_student_profile = Student.Profile.Model.setStudentDifficultyPreference model.profile new_difficulty_preference
    in
      (model, put_profile model.flags.csrftoken new_student_profile)

  ToggleUsernameUpdate ->
    (toggle_username_update model, Cmd.none)

  SubmitUsernameUpdate ->
    let
      profile = Student.Profile.Model.setUserName model.profile model.username_update.username
    in
      ({ model | profile = profile }, put_profile model.flags.csrftoken profile)

  CancelUsernameUpdate ->
    (toggle_username_update model, Cmd.none)

  Submitted (Ok student_profile) ->
    ({ model | profile = student_profile, editing = Dict.fromList [] }, Cmd.none)

  Submitted (Err err) -> let _ = Debug.log "submitted error" err in
    case err of
      Http.BadStatus resp ->
        case (Json.Decode.decodeString (Json.Decode.dict Json.Decode.string) resp.body) of
          Ok errors ->
            ({ model | errors = errors }, Cmd.none)
          _ ->
            (model, Cmd.none)

      Http.BadPayload err resp ->
        (model, Cmd.none)

      _ ->
        (model, Cmd.none)

  Logout msg ->
    (model, Student.Profile.Model.logout model.profile model.flags.csrftoken LoggedOut)

  LoggedOut (Ok logout_resp) ->
    (model, Ports.redirect logout_resp.redirect)

  LoggedOut (Err err) -> let _ = Debug.log "log out error" err in
      (model, Cmd.none)



main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

view_difficulty : Model -> Html Msg
view_difficulty model =
  let
    pref =
      (case Student.Profile.Model.studentDifficultyPreference model.profile of
        Just pref -> Tuple.first pref
        _ -> "")
  in
    div [] [
      Html.select [ onInput UpdateDifficulty ] [
        Html.optgroup [] (List.map (\(k,v) ->
          Html.option ([attribute "value" k] ++ (if k == pref then [attribute "selected" ""] else []))
         [ Html.text v ]) (Student.Profile.Model.studentDifficulties model.profile))
      ]
    ]

view_scores : TextReadingScore -> Html Msg
view_scores score =
  div [class "text_reading_item"] [
    Html.text ("Score: " ++ (toString score.complete_sections) ++ " / " ++ (toString score.num_of_sections))
  ]

view_text_reading_actions : TextReading -> Html Msg
view_text_reading_actions text_reading =
  let
    action_label =
      (case text_reading.status of
         "complete" -> "Start Over"
         _ -> "Resume")
  in
    div [class "text_reading_actions"] [
      div [] [
        Html.a [attribute "href" (Config.text_page text_reading.text_id)] [ Html.text action_label ]
      ]
    ]

view_text_reading : TextReading -> Html Msg
view_text_reading text_reading =
  div [] [
    div [class "text_reading_item"] [
      Html.text "Text: "
    , Html.text text_reading.text
    ]
  , div [class "text_reading_item"] [
      Html.text "Current Section: "
    , Html.text (Maybe.withDefault "None" text_reading.current_section)
    ]
  , div [class "text_reading_item"] [
      Html.text "Status: "
    , Html.text text_reading.status
    ]
  , view_scores text_reading.score
  , div [class "text_reading_item"] [
      Html.text "Actions"
    , view_text_reading_actions text_reading
    ]
  ]

view_student_text_readings : StudentProfile -> Html Msg
view_student_text_readings student_profile =
  let
    text_readings = Maybe.withDefault [] (Student.Profile.Model.studentTextReading student_profile)
  in
    div [class "text_readings"] [
      span [class "profile_item_title"] [ Html.text "Text Readings (Current and Complete)" ]
    , div [class "text_readings_values"] (List.map view_text_reading text_readings)
    ]

view_username_submit : UsernameUpdate -> List (Html Msg)
view_username_submit username =
  let
    cancel_btn = span [class "cursor", onClick CancelUsernameUpdate] [ Html.text "Cancel" ]
  in
    case username.valid of
      Just valid ->
        case valid of
          False ->
            []
          True ->
            [
              div [class "username_submit"] [
                span [class "cursor", onClick SubmitUsernameUpdate] [ Html.text "Submit" ]
              , cancel_btn
              ]
            ]

      Nothing ->
        [cancel_btn]

view_username : Model -> Html Msg
view_username model =
  let
    username = Student.Profile.Model.studentUserName model.profile
    username_valid_attrs =
      (case model.username_update.valid of
        Just valid ->
          case valid of
            True ->
              [class "valid_username"]
            False ->
              [class "invalid_username"]
        Nothing ->
          [])
    username_msgs =
      (case model.username_update.msg of
        Just msg ->
          [div [] [ Html.text msg ]]
        Nothing ->
          [])
  in
    div [class "profile_item"] [
      span [class "profile_item_title"] [ Html.text "Username" ]
    , case Dict.member "username" model.editing of
        False ->
          span [class "profile_item_value"] [
            Html.text (Student.Profile.Model.studentUserName model.profile)
          , div [class "update_username", class "cursor", onClick ToggleUsernameUpdate] [ Html.text "Update" ]
          ]
        True ->
          span [class "profile_item_value"] <| [
            Html.input [
              class "username_input"
            , attribute "placeholder" "Username"
            , attribute "value" username
            , attribute "maxlength" "150"
            , attribute "minlength" "8"
            , onInput UpdateUsername] []
          , span ([] ++ username_valid_attrs) []
          , div [class "username_msg"] username_msgs
          ] ++ view_username_submit model.username_update
    ]

view_user_email : Model -> Html Msg
view_user_email model =
  div [class "profile_item"] [
    span [class "profile_item_title"] [ Html.text "User E-Mail" ]
  , span [class "profile_item_value"] [
      Html.text (Student.Profile.Model.studentEmail model.profile)
    ]
  ]

view_preferred_difficulty : Model -> Html Msg
view_preferred_difficulty model =
  div [class "profile_item"] [
    span [class "profile_item_title"] [ Html.text "Preferred Difficulty" ]
  , span [class "profile_item_value"] [ (view_difficulty model) ]
  ]

view_flashcards : Model -> Html Msg
view_flashcards model =
  div [class "profile_item"] [
    span [class "profile_item_title"] [ Html.text "Words in flashcard bank: " ]
  , span [class "profile_item_value"] [
      div [] (List.map (\(normal_form, text_word) ->
        div [] [ span [] [ Html.text normal_form ] ]
       ) (Dict.toList <| Maybe.withDefault Dict.empty <| Student.Profile.Model.studentFlashcards model.profile))
    ]
  ]

view_student_performance : Model -> Html Msg
view_student_performance model =
  let
    performance_report_attrs = Student.Profile.Model.studentPerformanceReport model.profile
  in
    div [class "performance"] [
      span [class "profile_item_title"] [ Html.text "My Performance: " ]
    , span [class "profile_item_value"] [
        div [class "performance_report"]
         (HtmlParser.Util.toVirtualDom <| HtmlParser.parse performance_report_attrs.html)
      ]
    , div [class "performance_download_link"] [
        Html.a [attribute "href" performance_report_attrs.pdf_link] [
          Html.text "Download as PDF"
        ]
      ]
    ]

view_content : Model -> Html Msg
view_content model =
  div [ classList [("profile", True)] ] [
    div [classList [("profile_items", True)] ] [
      view_username model
    , view_user_email model
    , view_preferred_difficulty model
    , view_student_text_readings model.profile
    , view_student_performance model
    , view_flashcards model
    , (if not (String.isEmpty model.err_str) then
        span [attribute "class" "error"] [ Html.text "error", Html.text model.err_str ]
       else Html.text "")
    ]
  ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    Views.view_header (Profile.fromStudentProfile model.profile) Nothing Logout
  , view_content model
  , Views.view_footer
  ]
