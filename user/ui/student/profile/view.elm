module Student.Profile.View exposing (..)

import Dict exposing (Dict)
import Markdown

import HtmlParser
import HtmlParser.Util

import Html exposing (Html, div, span)
import Html.Attributes exposing (id, class, classList, attribute)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Student.Profile
import Student.Profile.Msg exposing (Msg(..))
import Student.Profile.Model exposing (UsernameUpdate, Model)

import Student.Profile.Help exposing (HelpMsg(..))

import Text.Reading.Model exposing (TextReading, TextReadingScore)
import Text.Model as Text

import Config


type alias HintAttributes = {
   cancel_event : Html.Attribute Msg
 , next_event : Html.Attribute Msg
 , prev_event : Html.Attribute Msg
 , help_msg : HelpMsg
 , addl_attributes : List (Html.Attribute Msg)
 }


view_difficulty : Model -> Html Msg
view_difficulty model =
  let
    pref = Tuple.first (Maybe.withDefault ("", "") (Student.Profile.studentDifficultyPreference model.profile))
  in
    div [] [
      Html.select [ onInput UpdateDifficulty ] [
        Html.optgroup [] (List.map (\(k,v) ->
          Html.option ([attribute "value" k] ++ (if k == pref then [attribute "selected" ""] else []))
         [ Html.text v ]) (Student.Profile.studentDifficulties model.profile))
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

view_student_welcome_msg : Student.Profile.StudentProfile -> Html Msg
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

view_hint_overlay : Model -> HintAttributes -> Html Msg
view_hint_overlay model {cancel_event, next_event, prev_event, addl_attributes, help_msg} =
  let
    visible = Student.Profile.Help.isVisible model.help help_msg
    msg_id = Student.Profile.Help.msgToId help_msg
  in
    span [ id msg_id
         , classList [("hint_overlay", True)
         , ("invisible", not visible)]] [
      span ([class "hint"] ++ addl_attributes) [
        span [class "msg"] [ Html.text (Student.Profile.Help.helpMsg help_msg) ]
      , span [class "exit"] [ view_cancel_btn cancel_event ]
      , span [class "nav"] [
          span [classList [("prev", False), ("cursor", True)], prev_event] [ Html.text "prev" ]
        , span [] [ Html.text " | " ]
        , span [classList [("next", False), ("cursor", True)], next_event] [ Html.text "next" ]
        ]
      ]
    ]

view_username_hint : Model -> List (Html Msg)
view_username_hint model =
  let
    username_help = Student.Profile.Help.username_help

    hint_attributes = {
       cancel_event = onClick (CloseHelp username_help)
     , next_event = onClick NextHelp
     , prev_event = onClick PrevHelp
     , addl_attributes = [class "username_hint"]
     , help_msg = username_help
     }
  in
    if model.flags.welcome then
      [
        view_hint_overlay model hint_attributes
      ]
    else
      []

view_username : Model -> Html Msg
view_username model =
  let
    username = Student.Profile.studentUserName model.profile

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
    div [class "profile_item"] <| (view_username_hint model) ++ [
      span [class "profile_item_title"] [ Html.text "Username" ]
    , case Dict.member "username" model.editing of
        False ->
          span [class "profile_item_value"] [
            Html.text (Student.Profile.studentUserName model.profile)
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
      Html.text (Student.Profile.studentEmail model.profile)
    ]
  ]

view_preferred_difficulty : Model -> Html Msg
view_preferred_difficulty model =
  div [class "preferred_difficulty"] [
    span [class "profile_item_title"] [ Html.text "Preferred Difficulty" ]
  , span [class "profile_item_value"] [
      view_difficulty model
    , view_help_text_for_difficulty (Student.Profile.studentDifficultyPreference model.profile)
    ]
  ]

view_flashcards : Model -> Html Msg
view_flashcards model =
  div [class "flashcards"] [
    span [class "profile_item_title"] [ Html.text "Flashcard Words" ]
  , span [class "profile_item_value"] [
      div [] (List.map (\(normal_form, text_word) ->
        div [] [ span [] [ Html.text normal_form ] ]
       ) (Dict.toList <| Maybe.withDefault Dict.empty <| Student.Profile.studentFlashcards model.profile))
    ]
  ]

view_my_performance_hint : Model -> List (Html Msg)
view_my_performance_hint model =
  let
    performance_help = Student.Profile.Help.my_performance_help

    hint_attributes = {
       cancel_event = onClick (CloseHelp performance_help)
     , next_event = onClick NextHelp
     , prev_event = onClick PrevHelp
     , addl_attributes = [class "performance_hint"]
     , help_msg = performance_help
     }
  in
    if model.flags.welcome then
      [
        view_hint_overlay model hint_attributes
      ]
    else
      []

view_student_performance : Model -> Html Msg
view_student_performance model =
  let
    performance_report_attrs = Student.Profile.studentPerformanceReport model.profile
  in
    div [class "performance"] <| (view_my_performance_hint model) ++ [
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