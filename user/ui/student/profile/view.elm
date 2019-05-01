module Student.Profile.View exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)
import Markdown

import OrderedDict exposing (OrderedDict)

import HtmlParser
import HtmlParser.Util

import Html exposing (Html, div, span)
import Html.Attributes exposing (id, class, classList, attribute)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Views
import Student.View

import Student.Profile
import Student.Profile.Msg exposing (Msg(..), HelpMsgs)
import Student.Profile.Model exposing (UsernameUpdate, Model)

import Student.Profile.Help exposing (StudentHelp(..))

import Text.Reading.Model exposing (TextReading, TextReadingScore)
import Text.Model as Text

import Menu.Item
import Menu.Items

import Menu.View
import Menu.Msg

import Help.View exposing (ArrowPlacement(..), ArrowPosition(..), view_hint_overlay)

import Config


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
      OrderedDict.fromList [
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

    default_list = (List.map (\(k, v) -> div [class "difficulty_desc"] [ v ]) (OrderedDict.toList difficulty_msgs))

    help_msg =
      (case text_difficulty of
        Just difficulty ->
          case OrderedDict.get (Tuple.first difficulty) difficulty_msgs of
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
    , class "cursor"
    , event_attr
    ] []

view_username_hint : Model -> List (Html Msg)
view_username_hint model =
  let
    username_help = Student.Profile.Help.username_help

    hint_attributes = {
       id = Student.Profile.Help.popupToOverlayID username_help
     , visible = Student.Profile.Help.isVisible model.help username_help
     , text = Student.Profile.Help.helpMsg username_help
     , cancel_event = onClick (CloseHelp username_help)
     , next_event = onClick NextHelp
     , prev_event = onClick PrevHelp
     , addl_attributes = [id (Student.Profile.Help.helpID model.help username_help)]
     , arrow_placement = ArrowDown ArrowLeft
     }
  in
    if model.flags.welcome then
      [
        Help.View.view_hint_overlay hint_attributes
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
            Html.text (Student.Profile.studentUserNameToString (Student.Profile.studentUserName model.profile))
          , div [class "update_username", class "cursor", onClick ToggleUsernameUpdate] [ Html.text "Update" ]
          ]

        True ->
          span [class "profile_item_value"] <| [
            Html.input [
              class "username_input"
            , attribute "placeholder" "Username"
            , attribute "value" (Student.Profile.studentUserNameToString username)
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
      Html.text (Student.Profile.studentEmailToString (Student.Profile.studentEmail model.profile))
    ]
  ]

view_difficulty_hint : Model -> List (Html Msg)
view_difficulty_hint model =
  let
    difficulty_help = Student.Profile.Help.preferred_difficulty_help

    hint_attributes = {
       id = Student.Profile.Help.popupToOverlayID difficulty_help
     , visible = Student.Profile.Help.isVisible model.help difficulty_help
     , text = Student.Profile.Help.helpMsg difficulty_help
     , cancel_event = onClick (CloseHelp difficulty_help)
     , next_event = onClick NextHelp
     , prev_event = onClick PrevHelp
     , addl_attributes = [id (Student.Profile.Help.helpID model.help difficulty_help)]
     , arrow_placement = ArrowDown ArrowLeft
     }
  in
    if model.flags.welcome then
      [
        Help.View.view_hint_overlay hint_attributes
      ]
    else
      []

view_preferred_difficulty : Model -> Html Msg
view_preferred_difficulty model =
  div [class "preferred_difficulty"] <| (view_difficulty_hint model) ++ [
    span [class "profile_item_title"] [ Html.text "Preferred Difficulty" ]
  , span [class "profile_item_value"] [
      view_difficulty model
    , view_help_text_for_difficulty (Student.Profile.studentDifficultyPreference model.profile)
    ]
  ]

view_flashcards : Model -> Html Msg
view_flashcards model =
  div [id "flashcards", class "profile_item"] [
    span [class "profile_item_title"] [ Html.text "Flashcard Words" ]
  , span [class "profile_item_value"] [
      div []
        (case model.flashcards of
           Just words ->
             List.map (\word -> div [] [ span [] [ Html.text word ] ]) words

           Nothing ->
             []
       )
    ]
  ]

view_research_consent : Model -> Html Msg
view_research_consent model =
  let
    consented = model.consenting_to_research
    consented_tooltip = "You've consented to be a part of a research study."
    no_consent_tooltip = "You have not consented to be a part of a research study."
  in
    div [id "research_consent", class "profile_item"] [
     span [class "profile_item_title"] [ Html.text "Research Consent" ]
    ,  span [class "profile_item_value"] [
          div [ classList [("check-box", True), ("check-box-selected", consented)]
              , onClick ToggleResearchConsent
              , attribute "title" (if consented then consented_tooltip else no_consent_tooltip)] []
        , div [class "check-box-text"] [ Html.text "I consent to research." ]
      ]
    ]

view_my_performance_hint : Model -> List (Html Msg)
view_my_performance_hint model =
  let
    performance_help = Student.Profile.Help.my_performance_help

    hint_attributes = {
       id = Student.Profile.Help.popupToOverlayID performance_help
     , visible = Student.Profile.Help.isVisible model.help performance_help
     , text = Student.Profile.Help.helpMsg performance_help
     , cancel_event = onClick (CloseHelp performance_help)
     , next_event = onClick NextHelp
     , prev_event = onClick PrevHelp
     , addl_attributes = [id (Student.Profile.Help.helpID model.help performance_help)]
     , arrow_placement = ArrowDown ArrowLeft
     }
  in
    if model.flags.welcome then
      [
        Help.View.view_hint_overlay hint_attributes
      ]
    else
      []

view_feedback_links : Model -> Html Msg
view_feedback_links model =
  div [class "feedback"] [
    span [class "profile_item_title"] [ Html.text "Contact" ]
  , span [class "profile_item_value"] [
      Views.view_report_problem
    , Views.view_give_feedback
    ]
  ]

view_student_performance : Model -> Html Msg
view_student_performance model =
  let
    performance_report = model.performance_report
  in
    div [class "performance"] <| (view_my_performance_hint model) ++ [
      span [class "profile_item_title"] [ Html.text "My Performance: " ]
    , span [class "profile_item_value"] [
        div [class "performance_report"]
         (HtmlParser.Util.toVirtualDom <| HtmlParser.parse performance_report.html)
      ]
    , div [class "performance_download_link"] [
        Html.a [attribute "href" performance_report.pdf_link] [
          Html.text "Download as PDF"
        ]
      ]
    ]

view_username_menu_item_hint : Model -> HelpMsgs msg -> List (Html msg)
view_username_menu_item_hint model help_msgs =
  let
    username_menu_item_help = Student.Profile.Help.username_menu_item_help

    hint_attributes = {
       id = Student.Profile.Help.popupToOverlayID username_menu_item_help
     , visible = Student.Profile.Help.isVisible model.help username_menu_item_help
     , text = Student.Profile.Help.helpMsg username_menu_item_help
     , cancel_event = onClick (help_msgs.close username_menu_item_help)
     , next_event = onClick help_msgs.next
     , prev_event = onClick help_msgs.prev
     , addl_attributes = [id (Student.Profile.Help.helpID model.help username_menu_item_help)]
     , arrow_placement = ArrowUp ArrowRight
     }
  in
    if model.flags.welcome then
      [
        Help.View.view_hint_overlay hint_attributes
      ]
    else
      []


view_search_menu_item_hint : Model -> HelpMsgs msg -> List (Html msg)
view_search_menu_item_hint model help_msgs =
  let
    search_menu_item_help = Student.Profile.Help.search_menu_item_help

    hint_attributes = {
       id = Student.Profile.Help.popupToOverlayID search_menu_item_help
     , visible = Student.Profile.Help.isVisible model.help search_menu_item_help
     , text = Student.Profile.Help.helpMsg search_menu_item_help
     , cancel_event = onClick (help_msgs.close search_menu_item_help)
     , next_event = onClick help_msgs.next
     , prev_event = onClick help_msgs.prev
     , addl_attributes = [id (Student.Profile.Help.helpID model.help search_menu_item_help)]
     , arrow_placement = ArrowUp ArrowLeft
     }
  in
    if model.flags.welcome then
      [
        Help.View.view_hint_overlay hint_attributes
      ]
    else
      []

view_menu_item : Model -> HelpMsgs msg -> Menu.Item.MenuItem -> Html msg
view_menu_item model help_msgs menu_item =
  let
    link_text = Menu.Item.linkTextToString menu_item
    addl_view =
      (case link_text == "Find a text to read" of
         True ->
            Just (view_search_menu_item_hint model help_msgs)

         False ->
            Nothing)
  in
    Menu.View.view_lower_menu_item menu_item addl_view

view_student_profile_page_link : Model -> HelpMsgs msg -> Html msg
view_student_profile_page_link model help_msgs =
  div [] [
    Html.a [attribute "href" (Student.Profile.profileUriToString model.profile)] [
      Html.text (Student.Profile.studentUserNameToString (Student.Profile.studentUserName model.profile))
    ]
  ]

view_student_profile_header : Model -> (Menu.Msg.Msg -> msg) -> HelpMsgs msg -> List (Html msg)
view_student_profile_header model top_level_menu_msg help_msgs =
  [
    Student.View.view_profile_dropdown_menu model.profile top_level_menu_msg [
      view_student_profile_page_link model help_msgs
    , Student.View.view_student_profile_logout_link model.profile top_level_menu_msg
    ]
  ] ++ (view_username_menu_item_hint model help_msgs)

view_top_level_menu : Model -> Menu.Items.MenuItems -> (Menu.Msg.Msg -> msg) -> HelpMsgs msg -> List (Html msg)
view_top_level_menu model menu_items top_level_menu_msg help_msgs =
  view_student_profile_header model top_level_menu_msg help_msgs

view_lower_level_menu : Model -> Menu.Items.MenuItems -> (Menu.Msg.Msg -> msg) -> HelpMsgs msg -> List (Html msg)
view_lower_level_menu model menu_items top_level_menu_msg help_msgs =
    (Array.toList
  <| Array.map (view_menu_item model help_msgs)
  <| (Menu.Items.items menu_items))

view_header : Model -> (Menu.Msg.Msg -> msg) -> HelpMsgs msg -> Html msg
view_header model top_level_menu_msg help_msgs =
  Views.view_header
    (view_top_level_menu model model.menu_items top_level_menu_msg help_msgs)
    (view_lower_level_menu model model.menu_items top_level_menu_msg help_msgs)
