module Pages.Text.Search exposing (Model, Msg, Params, page)

-- import Profile.Flags as Flags

import Browser
import Dict exposing (Dict)
import Help.View exposing (ArrowPlacement(..), ArrowPosition(..))
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, id)
import Html.Events exposing (onClick)
import Http exposing (..)
import InstructorAdmin.Admin.Text as AdminText
import Menu.Items
import Menu.Logout
import Menu.Msg as MenuMsg
import Ports exposing (clearInputText)
import Shared
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)
import Text.Decode
import Text.Model exposing (Text)
import Text.Search exposing (TextSearch)
import Text.Search.Difficulty exposing (DifficultySearch)
import Text.Search.Option
import Text.Search.ReadingStatus exposing (TextReadStatus, TextReadStatusSearch)
import Text.Search.Tag exposing (TagSearch)
import TextSearch.Help exposing (TextSearchHelp)
import User.Profile exposing (Profile)
import User.Student.Profile as StudentProfile
    exposing
        ( StudentProfile(..)
        , StudentURIs(..)
        )
import User.Student.Resource as StudentResource
import Utils.Date
import Views


page : Page Params Model Msg
page =
    Page.protectedApplication
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , save = save
        , load = load
        }



-- INIT


type alias Params =
    ()


type alias Model =
    Maybe SafeModel


type SafeModel
    = SafeModel
        { results : List Text.Model.TextListItem
        , profile : User.Profile.Profile

        -- , menu_items : Menu.Items.MenuItems
        , text_search : TextSearch
        , text_api_endpoint : AdminText.TextAPIEndpoint
        , help : TextSearch.Help.TextSearchHelp
        , error_msg : Maybe String
        , welcome : Bool

        -- , flags : Flags
        }



-- type alias Flags =
--     Flags.Flags
--         { text_difficulties : List Text.Model.TextDifficulty
--         , text_statuses : List ( String, String )
--         , text_api_endpoint_url : String
--         , welcome : Bool
--         , text_tags : List String
--         }


fakeProfile : Profile
fakeProfile =
    User.Profile.initProfile <|
        { student_profile =
            Just
                { id = Just 0
                , username = Just "fake name"
                , email = "test@email.com"
                , difficulty_preference = Nothing
                , difficulties = Shared.difficulties
                , uris =
                    { logout_uri = "logout"
                    , profile_uri = "profile"
                    }
                }
        , instructor_profile = Nothing
        }


init : Shared.Model -> Url Params -> ( SafeModel, Cmd Msg )
init shared { params } =
    let
        tag_search =
            Text.Search.Tag.new "text_tag_search"
                (Text.Search.Option.newOptions
                    -- (List.map (\tag -> ( tag, tag )) flags.text_tags)
                    (List.map (\tag -> ( tag, tag )) [])
                )

        difficulty_search =
            Text.Search.Difficulty.new
                "text_difficulty_search"
                (Text.Search.Option.newOptions Shared.difficulties)

        status_search =
            Text.Search.ReadingStatus.new
                "text_status_search"
                -- (Text.Search.Option.newOptions flags.text_statuses)
                (Text.Search.Option.newOptions [])

        text_api_endpoint =
            -- AdminText.TextAPIEndpoint
            --     (AdminText.URL flags.text_api_endpoint_url)
            AdminText.toTextAPIEndpoint "text-api-endpoint"

        default_search =
            Text.Search.new text_api_endpoint tag_search difficulty_search status_search

        profile =
            fakeProfile

        text_search =
            case profile of
                User.Profile.Student student_profile ->
                    case StudentProfile.studentDifficultyPreference student_profile of
                        Just difficulty ->
                            Text.Search.addDifficultyToSearch default_search (Tuple.first difficulty) True

                        _ ->
                            default_search

                _ ->
                    default_search

        text_search_help =
            TextSearch.Help.init

        -- menu_items =
        --     Menu.Items.initMenuItems flags
    in
    ( SafeModel
        { results = []
        , profile = fakeProfile

        --   , menu_items = menu_items
        , text_search = text_search
        , text_api_endpoint = text_api_endpoint
        , help = text_search_help
        , error_msg = Nothing
        , welcome = False

        --   , flags = flags
        }
      -- , updateResults text_api_endpoint text_search
    , Cmd.none
    )



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


update : Msg -> SafeModel -> ( SafeModel, Cmd Msg )
update msg (SafeModel model) =
    case msg of
        AddDifficulty difficulty select ->
            let
                new_text_search =
                    Text.Search.addDifficultyToSearch model.text_search difficulty select
            in
            ( SafeModel { model | text_search = new_text_search, results = [] }
              -- , updateResults model.text_api_endpoint new_text_search
            , Cmd.none
            )

        SelectStatus status selected ->
            let
                status_search =
                    Text.Search.statusSearch model.text_search

                new_status_search =
                    Text.Search.ReadingStatus.selectStatus status_search status selected

                new_text_search =
                    Text.Search.setStatusSearch model.text_search new_status_search
            in
            ( SafeModel { model | text_search = new_text_search, results = [] }
            , updateResults model.text_api_endpoint new_text_search
            )

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
            ( SafeModel { model | text_search = new_text_search, results = [] }
            , Cmd.batch [ clearInputText tag_search_input_id, updateResults model.text_api_endpoint new_text_search ]
            )

        TextSearch result ->
            case result of
                Ok texts ->
                    ( SafeModel { model | results = texts }, Cmd.none )

                Err err ->
                    let
                        _ =
                            Debug.log "error retrieving results" err
                    in
                    ( SafeModel { model | error_msg = Just "An error occurred.  Please contact an administrator." }, Cmd.none )

        CloseHelp help_msg ->
            ( SafeModel model
              -- ( SafeModel { model | help = TextSearch.Help.setVisible model.help help_msg False }
            , Cmd.none
            )

        PrevHelp ->
            ( SafeModel model
              -- ( SafeModel { model | help = TextSearch.Help.prev model.help }
            , Cmd.none
              -- , TextSearch.Help.scrollToPrevMsg model.help
            )

        NextHelp ->
            ( SafeModel model
              -- ( SafeModel { model | help = TextSearch.Help.next model.help }
            , Cmd.none
              -- , TextSearch.Help.scrollToNextMsg model.help
            )

        LogOut _ ->
            ( SafeModel model
            , Cmd.none
              -- , User.Profile.logout model.profile model.flags.csrftoken LoggedOut
            )

        LoggedOut (Ok logout_resp) ->
            ( SafeModel model, Ports.redirect logout_resp.redirect )

        LoggedOut (Err err) ->
            ( SafeModel model, Cmd.none )


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
            Debug.todo "query text list"

        -- Http.get query_string Text.Decode.textListDecoder
    in
    if List.length filter_params > 0 then
        Debug.todo "text search request"
        -- Http.send TextSearch request

    else
        Cmd.none



-- VIEW


view : SafeModel -> Document Msg
view (SafeModel model) =
    { title = "Search Texts"
    , body =
        [ div []
            -- [ Views.view_authed_header model.profile model.menu_items LogOut
            [ view_content (SafeModel model)
            , Views.view_footer
            ]
        ]
    }


view_content : SafeModel -> Html Msg
view_content (SafeModel model) =
    div [ id "text_search" ] <|
        (if model.welcome then
            [ view_help_msg (SafeModel model) ]

         else
            []
        )
            ++ [ view_search_filters (SafeModel model)
               , view_search_results model.results
               , view_search_footer (SafeModel model)
               ]


view_help_msg : SafeModel -> Html Msg
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


view_search_filters : SafeModel -> Html Msg
view_search_filters (SafeModel model) =
    div [ id "text_search_filters" ]
        [ div [ id "text_search_filters_label" ] [ Html.text "Filters" ]
        , div [ class "search_filter" ] <|
            [ div [ class "search_filter_title" ] [ Html.text "Difficulty" ]
            , div [] (view_difficulties (Text.Search.difficultySearch model.text_search))
            ]
                ++ view_difficulty_filter_hint (SafeModel model)
        , div [ class "search_filter" ]
            [ div [ class "search_filter_title" ] [ Html.text "Tags" ]
            , div [] <|
                [ view_tags (Text.Search.tagSearch model.text_search) ]
                    ++ view_topic_filter_hint (SafeModel model)
            ]
        , div [ class "search_filter" ] <|
            [ div [ class "search_filter_title" ] [ Html.text "Read Status" ]
            , div [] (view_statuses (Text.Search.statusSearch model.text_search))
            ]
                ++ view_status_filter_hint (SafeModel model)
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


view_search_footer : SafeModel -> Html Msg
view_search_footer (SafeModel model) =
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



-- HINTS


view_topic_filter_hint : SafeModel -> List (Html Msg)
view_topic_filter_hint (SafeModel model) =
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
    if model.welcome then
        [ Help.View.view_hint_overlay hint_attributes
        ]

    else
        []


view_difficulty_filter_hint : SafeModel -> List (Html Msg)
view_difficulty_filter_hint (SafeModel model) =
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
    if model.welcome then
        [ Help.View.view_hint_overlay hint_attributes
        ]

    else
        []


view_status_filter_hint : SafeModel -> List (Html Msg)
view_status_filter_hint (SafeModel model) =
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
    if model.welcome then
        [ Help.View.view_hint_overlay hint_attributes
        ]

    else
        []



-- SHARED


save : SafeModel -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> SafeModel -> ( SafeModel, Cmd Msg )
load shared safeModel =
    ( safeModel, Cmd.none )


subscriptions : SafeModel -> Sub Msg
subscriptions (SafeModel model) =
    Sub.none
