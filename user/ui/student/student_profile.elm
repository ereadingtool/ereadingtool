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

import Text.Model as Text

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

import Markdown


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
  -- help messages
  | CloseHelp String
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

  CloseHelp str ->
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

view_student_welcome_msg : StudentProfile -> Html Msg
view_student_welcome_msg student_profile =
  let
    welcome_title =
      """Welcome to The Language Flagship’s Steps To Advanced Reading (STAR) website."""
    welcome_msg =
     """
     The purpose of this site is to help students improve their reading proficiency in Flagship language that they
     are studying. This site includes a wide range of texts at different proficiency levels.
     You will select texts to read by proficiency level and by topic.
     Before reading the Russian texts, you will get a brief contextualizing message in English.
     Then you will see the first part of the text followed by comprehension questions.
     Once you’ve read the text and selected the best answer, you will get feedback telling you if your choice is
     correct, and why or why not. The format of this site resembles the Flagship proficiency tests, and our goal is to
      help you build your reading skills for those tests. Any particular reading should take you between 5-15 minutes
      to complete, and we envision that you can use these texts on the go, when commuting, when waiting for a bus, etc.
      You can come back to texts at any time.  If this is your first time using the website, pop-up boxes will help
      you learn how to use the site."""
  in
    div [class "welcome_msg"] [
      span [class "profile_item_title"] [ Html.text welcome_title ]
    , div [class "profile_item_value"] [Html.text welcome_msg]
    ]

view_help_text_for_difficulty : Maybe Text.TextDifficulty -> Html Msg
view_help_text_for_difficulty text_difficulty =
  let
    default_msg =
      """
      Strategy: Select a reading level that matches your current comfort level.  Read broadly in those texts.
      If you find that they are not particularly challenging after the 5-6th text, go back to your reader profile and
      select the next higher proficiency level. Once you find a level that is challenging, but not impossible, read all
      the texts on all the related topics for that level.  You will not need to select a difficulty level every time you
      log in, but you can choose to change your difficulty level at any time.
      """

    difficulty_msgs =
      Dict.fromList [
        ("intermediate_mid"
        , Markdown.toHtml [] """**Texts at the Intermediate Mid level** tend to be short public announcements,
        selections from personal correspondence, clearly organized texts in very recognizable genres with clear
        structure (like a biography, public opinion survey, etc.). Questions will focus on your ability to recognize
        the main ideas of the text. Typically, students in second year Russian can attempt texts at this level. """)
      , ("intermediate_high"
        , Markdown.toHtml [] """**Texts at the Intermediate High level** will tend to be several paragraphs in length,
        touching on topics of personal and/or public interest.  The texts will tell a story, give a description or
        explanation of something related to the topic. At the intermediate high level, you may be able to get the main
        idea of the text, but the supporting details may be elusive. Typically, students in third year Russian can
        attempt texts at this level.""")
      , ("advanced_low"
        , Markdown.toHtml [] """**Texts at the Advanced Low level** will be multiple paragraphs in length, touching on
        topics of public interest. They may be excerpts from straightforward literary texts, from newspapers relating
        the circumstances related to an event of public interest.  Texts may related to present, past or future time
        frames. Advanced Low texts will show a strong degree of internal cohesion and organization.  The paragraphs
        cannot be rearranged without doing damage to the comprehensibility of the passage. At the Advanced low level,
        you should be able to understand the main ideas of the passage as well as the supporting details.
        Readers at the Advanced Low level can efficiently balance the use of background knowledge WITH linguistic
        knowledge to determine the meaning of a text, although complicated word order may interfere with the reader’s
        comprehension. Typically, students in fourth year Russian can attempt these texts. """)
      , ("advanced_mid"
        , Markdown.toHtml [] """**Texts at the Advanced Mid level** will be even longer than at the Advanced Low level.
        They will address issues of public interest, and they may contain narratives, descriptions, explanations, and
        some argumentation, laying out and justifying a particular point of view. At the Advanced Mid level, texts
        contain cultural references that are important for following the author’s point of view and argumentation.
        Texts may contain unusual plot twists and unexpected turns of events, but they do not confuse readers because
        readers have a strong command of the vocabulary, syntax, rhetorical devices that organize texts. Readers at the
        Advanced Mid level can handle the main ideas and the factual details of texts. Typically, strong students in
        4th year Russian or in 5th year Russian can attempt texts at this level. """)
      ]

    default_list = (List.map (\(k, v) -> div [class "difficulty_desc"] [ v ]) (Dict.toList difficulty_msgs))

    help_msg =
      (case text_difficulty of
        Just difficulty ->
          case Dict.get (Tuple.first difficulty) difficulty_msgs of
            Just difficulty_msg ->
              div [] [ difficulty_msg ]

            Nothing ->
              div [] ([ Html.text default_msg ] ++ default_list)

        Nothing ->
          div [] ([ Html.text default_msg ] ++ default_list ) )
  in
    div [class "difficulty_descs"] [
      div [class "text_readings_values"] [help_msg]
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

view_cancel_btn : Html.Attribute Msg -> Html Msg
view_cancel_btn event_attr =
  Html.img [
      attribute "src" "/static/img/cancel.svg"
    , attribute "height" "13px"
    , attribute "width" "13px"
    , class "cursor"
    , event_attr
    ] []

view_hint_overlay : Html.Attribute Msg -> String -> Html Msg
view_hint_overlay event_attr hint_msg =
  span [class "hint_overlay"] [
    span [class "hint"] [
      span [class "msg"] [ Html.text hint_msg ]
    , span [class "exit"] [ view_cancel_btn event_attr ]
    , span [class "nav"] [
        Html.text "prev | next"
      ]
    ]
  ]

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

    username_hint =
      """You can create a new username that is distinct from your email address if you choose.
      Your username will be visible to instructors and other students if you comment on any texts."""

  in
    div [class "profile_item"] [
      view_hint_overlay (onClick (CloseHelp "user")) username_hint
    , span [class "profile_item_title"] [ Html.text "Username" ]
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
          , span username_valid_attrs []
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
  div [class "preferred_difficulty"] [
    span [class "profile_item_title"] [ Html.text "Preferred Difficulty" ]
  , span [class "profile_item_value"] [
      view_difficulty model
    , view_help_text_for_difficulty (Student.Profile.Model.studentDifficultyPreference model.profile)
    ]
  ]

view_flashcards : Model -> Html Msg
view_flashcards model =
  div [class "flashcards"] [
    span [class "profile_item_title"] [ Html.text "Flashcard Words" ]
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
      view_student_welcome_msg model.profile
    , view_preferred_difficulty model
    , view_username model
    , view_user_email model
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
