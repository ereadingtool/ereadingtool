module TextSearch exposing (Flags, Model, Msg(..), init, main, subscriptions, update, updateResults, view, view_content, view_difficulties, view_difficulty_filter_hint, view_help_msg, view_search_filters, view_search_footer, view_search_results, view_status_filter_hint, view_statuses, view_tags, view_topic_filter_hint)

import Browser
import Dict exposing (Dict)
import Help.View exposing (ArrowPlacement(..), ArrowPosition(..))
import Html exposing (Html, div, option)
import Html.Attributes exposing (attribute, class, classList, id)
import Html.Events exposing (onClick)
import Http exposing (..)
import InstructorAdmin.Admin.Text as AdminText
import Menu.Items
import Menu.Logout
import Menu.Msg as MenuMsg
import Ports exposing (clearInputText)
import Profile.Flags as Flags
import Student.Profile
import Text.Decode
import Text.Model exposing (Text)
import Text.Search exposing (TextSearch)
import Text.Search.Difficulty exposing (DifficultySearch)
import Text.Search.Option
import Text.Search.ReadingStatus exposing (TextReadStatus, TextReadStatusSearch)
import Text.Search.Tag exposing (TagSearch)
import TextSearch.Help exposing (TextSearchHelp)
import User.Profile
import Utils.Date
import Views



-- UPDATE


type Msg
    = AddDifficulty String Bool
    | SelectTag String Bool
    | SelectStatus TextReadStatus Bool
    | TextSearch (Result Http.Error (List Text.Model.TextListItem))
      -- help messages
    | CloseHelp TextSearch.Help.TextHelp
    | PrevHelp
    | NextHelp
      -- site-wide messages
    | LogOut MenuMsg.Msg
    | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)


type alias Flags =
    Flags.Flags
        { text_difficulties : List Text.Model.TextDifficulty
        , text_statuses : List ( String, String )
        , text_api_endpoint_url : String
        , welcome : Bool
        , text_tags : List String
        }


type alias Model =
    { results : List Text.Model.TextListItem
    , profile : User.Profile.Profile
    , menu_items : Menu.Items.MenuItems
    , text_search : TextSearch
    , text_api_endpoint : AdminText.TextAPIEndpoint
    , help : TextSearch.Help.TextSearchHelp
    , error_msg : Maybe String
    , flags : Flags
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        tag_search =
            Text.Search.Tag.new "text_tag_search"
                (Text.Search.Option.newOptions (List.map (\tag -> ( tag, tag )) flags.text_tags))

        difficulty_search =
            Text.Search.Difficulty.new "text_difficulty_search" (Text.Search.Option.newOptions flags.text_difficulties)

        profile =
            User.Profile.initProfile flags

        status_search =
            Text.Search.ReadingStatus.new "text_status_search" (Text.Search.Option.newOptions flags.text_statuses)

        text_api_endpoint =
            AdminText.TextAPIEndpoint (AdminText.URL flags.text_api_endpoint_url)

        default_search =
            Text.Search.new text_api_endpoint tag_search difficulty_search status_search

        text_search =
            case profile of
                User.Profile.Student student_profile ->
                    case Student.Profile.studentDifficultyPreference student_profile of
                        Just difficulty ->
                            Text.Search.addDifficultyToSearch default_search (Tuple.first difficulty) True

                        _ ->
                            default_search

                _ ->
                    default_search

        text_search_help =
            TextSearch.Help.init

        menu_items =
            Menu.Items.initMenuItems flags
    in
    ( { results = []
      , profile = profile
      , menu_items = menu_items
      , text_search = text_search
      , text_api_endpoint = text_api_endpoint
      , help = text_search_help
      , error_msg = Nothing
      , flags = flags
      }
    , updateResults text_api_endpoint text_search
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


updateResults : AdminText.TextAPIEndpoint -> TextSearch -> Cmd Msg
updateResults text_api_endpoint text_search =
    let
        text_api_endpoint_url =
            AdminText.textEndpointToString text_api_endpoint

        filter_params =
            Text.Search.filterParams text_search

        query_string =
            String.join "" [ text_api_endpoint_url, "?" ] ++ String.join "&" filter_params

        request =
            Http.get query_string Text.Decode.textListDecoder
    in
    if List.length filter_params > 0 then
        Http.send TextSearch request

    else
        Cmd.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddDifficulty difficulty select ->
            let
                new_text_search =
                    Text.Search.addDifficultyToSearch model.text_search difficulty select
            in
            ( { model | text_search = new_text_search, results = [] }, updateResults model.text_api_endpoint new_text_search )

        SelectStatus status selected ->
            let
                status_search =
                    Text.Search.statusSearch model.text_search

                new_status_search =
                    Text.Search.ReadingStatus.selectStatus status_search status selected

                new_text_search =
                    Text.Search.setStatusSearch model.text_search new_status_search
            in
            ( { model | text_search = new_text_search, results = [] }, updateResults model.text_api_endpoint new_text_search )

        SelectTag tag_name selected ->
            let
                tag_search =
                    Text.Search.tagSearch model.text_search

                tag_search_input_id =
                    Text.Search.Tag.inputID tag_search

                new_tag_search =
                    Text.Search.Tag.select_tag tag_search tag_name selected

                new_text_search =
                    Text.Search.setTagSearch model.text_search new_tag_search
            in
            ( { model | text_search = new_text_search, results = [] }
            , Cmd.batch [ clearInputText tag_search_input_id, updateResults model.text_api_endpoint new_text_search ]
            )

        TextSearch result ->
            case result of
                Ok texts ->
                    ( { model | results = texts }, Cmd.none )

                Err err ->
                    let
                        _ =
                            Debug.log "error retrieving results" err
                    in
                    ( { model | error_msg = Just "An error occurred.  Please contact an administrator." }, Cmd.none )

        CloseHelp help_msg ->
            ( { model | help = TextSearch.Help.setVisible model.help help_msg False }, Cmd.none )

        PrevHelp ->
            ( { model | help = TextSearch.Help.prev model.help }, TextSearch.Help.scrollToPrevMsg model.help )

        NextHelp ->
            ( { model | help = TextSearch.Help.next model.help }, TextSearch.Help.scrollToNextMsg model.help )

        LogOut _ ->
            ( model, User.Profile.logout model.profile model.flags.csrftoken LoggedOut )

        LoggedOut (Ok logout_resp) ->
            ( model, Ports.redirect logout_resp.redirect )

        LoggedOut (Err err) ->
            ( model, Cmd.none )


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , subscriptions = subscriptions
        , update = update
        }


view_tags : TagSearch -> Html Msg
view_tags tag_search =
    let
        tags =
            Text.Search.Tag.optionsToDict tag_search

        tag_search_id =
            Text.Search.Tag.inputID tag_search

        view_tag tag_search_option =
            let
                selected =
                    Text.Search.Option.selected tag_search_option

                tag_value =
                    Text.Search.Option.value tag_search_option

                tag_label =
                    Text.Search.Option.label tag_search_option
            in
            div
                [ onClick (SelectTag tag_value (not selected))
                , classList
                    [ ( "text_tag", True )
                    , ( "text_tag_selected", selected )
                    ]
                ]
                [ Html.text tag_label
                ]
    in
    div [ id "text_tags" ]
        [ div [ class "text_tags" ] (List.map view_tag (Dict.values tags))
        ]


view_difficulties : DifficultySearch -> List (Html Msg)
view_difficulties difficulty_search =
    let
        difficulties =
            Text.Search.Difficulty.options difficulty_search

        view_difficulty difficulty_search_option =
            let
                selected =
                    Text.Search.Option.selected difficulty_search_option

                value =
                    Text.Search.Option.value difficulty_search_option

                label =
                    Text.Search.Option.label difficulty_search_option
            in
            div
                [ classList [ ( "difficulty_option", True ), ( "difficulty_option_selected", selected ) ]
                , onClick (AddDifficulty value (not selected))
                ]
                [ Html.text label
                ]
    in
    List.map view_difficulty difficulties


view_statuses : TextReadStatusSearch -> List (Html Msg)
view_statuses status_search =
    let
        statuses =
            Text.Search.ReadingStatus.options status_search

        view_status ( value, status_option ) =
            let
                selected =
                    Text.Search.Option.selected status_option

                label =
                    Text.Search.Option.label status_option

                status =
                    Text.Search.ReadingStatus.valueToStatus value
            in
            div
                [ classList [ ( "text_status", True ), ( "text_status_option_selected", selected ) ]
                , onClick (SelectStatus status (not selected))
                ]
                [ Html.text label
                ]
    in
    List.map view_status <| List.map (\option -> ( Text.Search.Option.value option, option )) statuses


view_search_filters : Model -> Html Msg
view_search_filters model =
    div [ id "text_search_filters" ]
        [ div [ id "text_search_filters_label" ] [ Html.text "Filters" ]
        , div [ class "search_filter" ] <|
            [ div [ class "search_filter_title" ] [ Html.text "Difficulty" ]
            , div [] (view_difficulties (Text.Search.difficultySearch model.text_search))
            ]
                ++ view_difficulty_filter_hint model
        , div [ class "search_filter" ]
            [ div [ class "search_filter_title" ] [ Html.text "Tags" ]
            , div [] <| [ view_tags (Text.Search.tagSearch model.text_search) ] ++ view_topic_filter_hint model
            ]
        , div [ class "search_filter" ] <|
            [ div [ class "search_filter_title" ] [ Html.text "Read Status" ]
            , div [] (view_statuses (Text.Search.statusSearch model.text_search))
            ]
                ++ view_status_filter_hint model
        ]


view_search_results : List Text.Model.TextListItem -> Html Msg
view_search_results textListItems =
    let
        view_search_result textItem =
            let
                commaDelimitedTags =
                    case textItem.tags of
                        Just tags ->
                            String.join ", " tags

                        Nothing ->
                            ""

                sectionsCompleted =
                    case textItem.text_sections_complete of
                        Just sections_complete ->
                            String.fromInt sections_complete ++ " / " ++ String.fromInt textItem.text_section_count

                        Nothing ->
                            "0 / " ++ String.fromInt textItem.text_section_count

                lastRead =
                    case textItem.last_read_dt of
                        Just dt ->
                            Utils.Date.monthDayYearFormat dt

                        Nothing ->
                            ""

                questionsCorrect =
                    case textItem.questions_correct of
                        Just correct ->
                            String.fromInt (Tuple.first correct) ++ " out of " ++ String.fromInt (Tuple.second correct)

                        Nothing ->
                            "None"
            in
            div [ class "search_result" ]
                [ div [ class "result_item" ]
                    [ div [ class "result_item_title" ] [ Html.a [ attribute "href" textItem.uri ] [ Html.text textItem.title ] ]
                    , div [ class "sub_description" ] [ Html.text "Title" ]
                    ]
                , div [ class "result_item" ]
                    [ div [ class "result_item_title" ] [ Html.text textItem.difficulty ]
                    , div [ class "sub_description" ] [ Html.text "Difficulty" ]
                    ]
                , div [ class "result_item" ]
                    [ div [ class "result_item_title" ] [ Html.text textItem.author ]
                    , div [ class "sub_description" ] [ Html.text "Author" ]
                    ]
                , div [ class "result_item" ]
                    [ div [ class "result_item_title" ] [ Html.text sectionsCompleted ]
                    , div [ class "sub_description" ] [ Html.text "Sections Complete" ]
                    ]
                , div [ class "result_item" ]
                    [ div [ class "result_item_title" ] [ Html.text commaDelimitedTags ]
                    , div [ class "sub_description" ] [ Html.text "Tags" ]
                    ]
                , div [ class "result_item" ]
                    [ div [ class "result_item_title" ] [ Html.text lastRead ]
                    , div [ class "sub_description" ] [ Html.text "Last Read" ]
                    ]
                , div [ class "result_item" ]
                    [ div [ class "result_item_title" ] [ Html.text questionsCorrect ]
                    , div [ class "sub_description" ] [ Html.text "Questions Correct" ]
                    ]
                ]
    in
    div [ id "text_search_results" ] (List.map view_search_result textListItems)


view_search_footer : Model -> Html Msg
view_search_footer model =
    let
        results_length =
            List.length model.results

        entries =
            if results_length == 1 then
                "entry"

            else
                "entries"

        success_txt =
            String.join " " [ "Showing", String.fromInt results_length, entries ]

        txt =
            case model.error_msg of
                Just msg ->
                    msg

                Nothing ->
                    success_txt
    in
    div [ id "footer_items" ]
        [ div [ id "footer", class "message" ]
            [ Html.text txt
            ]
        ]


view_help_msg : Model -> Html Msg
view_help_msg model =
    div [ id "text_search_help_msg" ]
        [ div []
            [ Html.text "Welcome."
            ]
        , div []
            [ Html.text
                """Use this page to find texts for your proficiency level and on topics that are of interest to you."""
            ]
        , div []
            [ Html.text
                """To walk through a demonstration of how the text and questions appear, please select Intermediate-Mid
       from the Difficulty tags and then Other from the the Topic tags, and Unread from the Status Filters.
       A text entitled Demo Text should appear at the top of the list.  Click on the title to go to this text."""
            ]
        ]


view_topic_filter_hint : Model -> List (Html Msg)
view_topic_filter_hint model =
    let
        topic_filter_help =
            TextSearch.Help.topic_filter_help

        hint_attributes =
            { id = TextSearch.Help.popupToID topic_filter_help
            , visible = TextSearch.Help.isVisible model.help topic_filter_help
            , text = TextSearch.Help.helpMsg topic_filter_help
            , cancel_event = onClick (CloseHelp topic_filter_help)
            , next_event = onClick NextHelp
            , prev_event = onClick PrevHelp
            , addl_attributes = [ class "difficulty_filter_hint" ]
            , arrow_placement = ArrowUp ArrowLeft
            }
    in
    if model.flags.welcome then
        [ Help.View.view_hint_overlay hint_attributes
        ]

    else
        []


view_difficulty_filter_hint : Model -> List (Html Msg)
view_difficulty_filter_hint model =
    let
        difficulty_filter_help =
            TextSearch.Help.difficulty_filter_help

        hint_attributes =
            { id = TextSearch.Help.popupToID difficulty_filter_help
            , visible = TextSearch.Help.isVisible model.help difficulty_filter_help
            , text = TextSearch.Help.helpMsg difficulty_filter_help
            , cancel_event = onClick (CloseHelp difficulty_filter_help)
            , next_event = onClick NextHelp
            , prev_event = onClick PrevHelp
            , addl_attributes = [ class "difficulty_filter_hint" ]
            , arrow_placement = ArrowUp ArrowLeft
            }
    in
    if model.flags.welcome then
        [ Help.View.view_hint_overlay hint_attributes
        ]

    else
        []


view_status_filter_hint : Model -> List (Html Msg)
view_status_filter_hint model =
    let
        status_filter_help =
            TextSearch.Help.status_filter_help

        hint_attributes =
            { id = TextSearch.Help.popupToID status_filter_help
            , visible = TextSearch.Help.isVisible model.help status_filter_help
            , text = TextSearch.Help.helpMsg status_filter_help
            , cancel_event = onClick (CloseHelp status_filter_help)
            , next_event = onClick NextHelp
            , prev_event = onClick PrevHelp
            , addl_attributes = [ class "status_filter_hint" ]
            , arrow_placement = ArrowUp ArrowLeft
            }
    in
    if model.flags.welcome then
        [ Help.View.view_hint_overlay hint_attributes
        ]

    else
        []


view_content : Model -> Html Msg
view_content model =
    div [ id "text_search" ] <|
        (if model.flags.welcome then
            [ view_help_msg model ]

         else
            []
        )
            ++ [ view_search_filters model
               , view_search_results model.results
               , view_search_footer model
               ]



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ Views.view_authed_header model.profile model.menu_items LogOut
        , view_content model
        , Views.view_footer
        ]
