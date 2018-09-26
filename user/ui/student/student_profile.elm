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

-- UPDATE
type Msg =
    UpdateStudentProfile (Result Error StudentProfile)
  | UpdateDifficulty String
  | UserNameUpdate
  | UpdateUsername String
  | SubmitUsernameUpdate
  | ValidUsername (Result Error Username)
  | Submitted (Result Error UpdateProfileResp)
  | Logout MenuMsg.Msg
  | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)

type alias Flags = Flags.Flags {}

type alias Username = { username: String, valid: Maybe Bool, msg: Maybe String }

type alias Model = {
    flags : Flags
  , profile : StudentProfile
  , editing : Dict String Bool
  , err_str : String
  , username : Username
  , errors : Dict String String }

type alias UpdateProfileResp = Dict.Dict String String

updateRespDecoder : Json.Decode.Decoder (UpdateProfileResp)
updateRespDecoder = Json.Decode.dict Json.Decode.string

username_valid_encode : String -> Json.Encode.Value
username_valid_encode username =
  Json.Encode.object [("username", Json.Encode.string username)]

username_valid_decoder : Json.Decode.Decoder Username
username_valid_decoder =
  decode Username
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
           (Http.jsonBody encoded_profile) updateRespDecoder
      in
        Http.send Submitted req
    Nothing ->
      Cmd.none

init : Flags -> (Model, Cmd Msg)
init flags = ({
    flags = flags
  , profile = Student.Profile.Model.emptyStudentProfile
  , editing = Dict.fromList []
  , username = {username = "", valid = Nothing, msg = Nothing}
  , err_str = "", errors = Dict.fromList [] }, Profile.retrieve_student_profile UpdateStudentProfile flags.profile_id)

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
  UpdateStudentProfile (Ok profile) ->
    let
      username = model.username
      new_username = { username | username = Student.Profile.Model.studentUserName profile }
    in
      ({ model | profile = profile, username = new_username }, Cmd.none)

  -- handle user-friendly msgs
  UpdateStudentProfile (Err err) ->
    ({ model | err_str = toString err }, Cmd.none)

  UpdateUsername value ->
    let
      username = model.username
      new_username = { username | username = value }
    in
      ({ model | username = new_username }, validate_username model.flags.csrftoken value)

  ValidUsername (Ok username) ->
    ({ model | username = username }, Cmd.none)

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
      (model, put_profile model.flags.csrftoken new_student_profile )

  UserNameUpdate ->
    (toggle_username_update model, Cmd.none)

  SubmitUsernameUpdate ->
    let
      profile = Student.Profile.Model.setUserName model.profile model.username.username
    in
      ({ model | profile = profile }, put_profile model.flags.csrftoken profile)

  Submitted (Ok resp) ->
    (toggle_username_update model, Cmd.none)

  Submitted (Err err) ->
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
  span [] [
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
    div [class "profile_item"] [
      span [class "profile_item_title"] [ Html.text "Text Readings (Current and Complete)" ]
    , span [class "profile_item_value"] (List.map view_text_reading text_readings)
    ]

view_username_submit : Username -> List (Html Msg)
view_username_submit username =
  case username.valid of
    Just valid ->
      case valid of
        False ->
          []
        True ->
          [ div [class "username_submit", class "cursor", onClick SubmitUsernameUpdate] [Html.text "Update"] ]

    Nothing ->
      []

view_username : Model -> Html Msg
view_username model =
  let
    username = Student.Profile.Model.studentUserName model.profile
    username_valid_attrs =
      (case model.username.valid of
        Just valid ->
          case valid of
            True ->
              [class "valid_username"]
            False ->
              [class "invalid_username"]
        Nothing ->
          [])
    username_msgs =
      (case model.username.msg of
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
          , div [class "update_username", class "cursor", onClick UserNameUpdate] [ Html.text "Update" ]
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
          ] ++ view_username_submit model.username
    ]

view_content : Model -> Html Msg
view_content model =
  div [ classList [("profile", True)] ] [
    div [classList [("profile_items", True)] ] [
      view_username model
    , div [class "profile_item"] [
        span [class "profile_item_title"] [ Html.text "User E-Mail" ]
      , span [class "profile_item_value"] [
          Html.text (Student.Profile.Model.studentEmail model.profile)
        ]
      ]
    , div [class "profile_item"] [
        span [class "profile_item_title"] [ Html.text "Preferred Difficulty" ]
      , span [class "profile_item_value"] [ (view_difficulty model) ]
      ]
    , div [class "profile_item"] [
          span [class "profile_item_title"] [ Html.text "Flashcards: " ]
        , span [class "profile_item_value"] [
            div [] (List.map (\fake_name ->
              div [] [ Html.a [attribute "href" "#"] [ Html.text fake_name ] ]
            ) ["word", "word", "word"])
          ]
      ]
    , view_student_text_readings model.profile
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
