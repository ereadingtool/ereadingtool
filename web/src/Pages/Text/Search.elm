module Pages.Text.Search exposing (Model, Msg, Params, page)

import Api
import Api.Config as Config exposing (Config)
import Api.Endpoint as Endpoint
import Browser.Navigation exposing (Key)
import Dict
import Help.View exposing (ArrowPlacement(..), ArrowPosition(..))
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, href, id)
import Html.Events exposing (onClick)
import Http
import Http.Detailed
import Json.Decode
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode exposing (Value)
import Ports exposing (clearInputText)
import Role exposing (Role(..))
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Task
import Text.Decode
import Text.Model
import Text.Search exposing (TextSearch)
import Text.Search.Difficulty exposing (DifficultySearch)
import Text.Search.Option
import Text.Search.ReadingStatus exposing (TextReadStatus, TextReadStatusSearch)
import Text.Search.Tag exposing (TagSearch)
import TextSearch.Help
import Time exposing (Zone)
import Url.Builder exposing (QueryParameter)
import User.Profile
import User.Student.Profile as StudentProfile
import Utils.Date
import Viewer
import Vote exposing (Vote(..))


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

type alias VoteResponse =
    { textId : Int
    , vote : Vote
    , rating : Int
    }


type alias Params =
    ()


type alias Model =
    Maybe SafeModel


type SafeModel
    = SafeModel
        { session : Session
        , config : Config
        , navKey : Key
        , timezone : Zone
        , results : List Text.Model.TextListItem
        , profile : User.Profile.Profile
        , textSearch : TextSearch
        , help : TextSearch.Help.TextSearchHelp
        , showHelp : Bool
        , errorMessage : Maybe String
        }


init : Shared.Model -> Url Params -> ( SafeModel, Cmd Msg )
init shared { params } =
    let
        tagSearch =
            Text.Search.Tag.new "text_tag_search"
                (Text.Search.Option.newOptions
                    (List.map (\tag -> ( tag, tag )) Shared.tags)
                )

        difficultySearch =
            Text.Search.Difficulty.new
                "text_difficulty_search"
                (Text.Search.Option.newOptions Shared.difficulties)

        statusSearch =
            Text.Search.ReadingStatus.new
                "text_status_search"
                (Text.Search.Option.newOptions Shared.statuses)

        defaultSearch =
            Text.Search.new tagSearch difficultySearch statusSearch

        textSearch =
            case shared.profile of
                User.Profile.Student student_profile ->
                    case StudentProfile.studentDifficultyPreference student_profile of
                        Just difficulty ->
                            Text.Search.addDifficultyToSearch defaultSearch (Tuple.first difficulty) True

                        _ ->
                            Text.Search.addDifficultyToSearch defaultSearch "intermediate_mid" True

                _ ->
                    Text.Search.addDifficultyToSearch defaultSearch "intermediate_mid" True

        textSearchHelp =
            TextSearch.Help.init

        showHelp =
            case Session.viewer shared.session of
                Just viewer ->
                    case Viewer.role viewer of
                        Student ->
                            Config.showHelp shared.config

                        Instructor ->
                            False

                Nothing ->
                    False
    in
    ( SafeModel
        { session = shared.session
        , config = shared.config
        , navKey = shared.key
        , timezone = shared.timezone
        , results = []
        , profile = shared.profile
        , textSearch = textSearch
        , help = textSearchHelp
        , showHelp = showHelp
        , errorMessage = Nothing
        }
    , Cmd.batch
        [ updateResults shared.session shared.config textSearch
        , Api.websocketDisconnectAll
        ]
    )



-- UPDATE


type Msg
    = AddDifficulty String Bool
    | SelectTag String Bool
    | SelectStatus TextReadStatus Bool
    | TextSearch (Result (Http.Detailed.Error String) ( Http.Metadata, List Text.Model.TextListItem ))
      -- help messages
    | CloseHint TextSearch.Help.TextHelp
    | PreviousHint
    | NextHint
      -- rating messages
    | Vote Vote Int
    | GotVote (Result (Http.Detailed.Error String) ( Http.Metadata, VoteResponse ))
      -- site-wide messages
    | Logout


update : Msg -> SafeModel -> ( SafeModel, Cmd Msg )
update msg (SafeModel model) =
    case msg of
        AddDifficulty difficulty select ->
            let
                newTextSearch =
                    Text.Search.addDifficultyToSearch model.textSearch difficulty select
            in
            ( SafeModel { model | textSearch = newTextSearch, results = [] }
            , updateResults model.session model.config newTextSearch
            )

        SelectStatus status selected ->
            let
                statusSearch =
                    Text.Search.statusSearch model.textSearch

                newStatusSearch =
                    Text.Search.ReadingStatus.selectStatus statusSearch status selected

                newTextSearch =
                    Text.Search.setStatusSearch model.textSearch newStatusSearch
            in
            ( SafeModel { model | textSearch = newTextSearch, results = [] }
            , updateResults model.session model.config newTextSearch
            )

        SelectTag tagName selected ->
            let
                tagSearch =
                    Text.Search.tagSearch model.textSearch

                tagSearchInputId =
                    Text.Search.Tag.inputID tagSearch

                newTagSearch =
                    Text.Search.Tag.select_tag tagSearch tagName selected

                newTextSearch =
                    Text.Search.setTagSearch model.textSearch newTagSearch
            in
            ( SafeModel { model | textSearch = newTextSearch, results = [] }
            , Cmd.batch
                [ clearInputText tagSearchInputId
                , updateResults model.session model.config newTextSearch
                ]
            )

        TextSearch (Ok ( metadata, texts )) ->
            let
                maybeErrorMessage =
                    if List.isEmpty texts then
                        Just "No results found. Please try another search."

                    else
                        Nothing
            in
            ( SafeModel
                { model
                    | results = texts
                    , errorMessage = maybeErrorMessage
                }
            , Cmd.none
            )

        TextSearch (Err error) ->
            case error of
                Http.Detailed.BadStatus metadata body ->
                    if metadata.statusCode == 403 then
                        ( SafeModel model
                        , Api.logout ()
                        )

                    else
                        ( SafeModel { model | errorMessage = Just "An error occurred.  Please contact an administrator." }
                        , Cmd.none
                        )

                _ ->
                    ( SafeModel { model | errorMessage = Just "An error occurred.  Please contact an administrator." }
                    , Cmd.none
                    )

        CloseHint helpMessage ->
            ( SafeModel { model | help = TextSearch.Help.setVisible model.help helpMessage False }
            , Cmd.none
            )

        PreviousHint ->
            ( SafeModel { model | help = TextSearch.Help.prev model.help }
            , TextSearch.Help.scrollToPrevMsg model.help
            )

        NextHint ->
            ( SafeModel { model | help = TextSearch.Help.next model.help }
            , TextSearch.Help.scrollToNextMsg model.help
            )

        Vote vote textId ->
            ( SafeModel model
            , updateRating model.session model.config vote textId model.textSearch
            )

        GotVote (Ok ( _, voteResponse )) ->
            let
                textId =
                    voteResponse.textId

                vote =
                    voteResponse.vote

                rating =
                    voteResponse.rating

                indexedTextItems =
                    List.indexedMap Tuple.pair model.results

                updatedTextItemRating =
                    List.filter (\indexedTextItem -> (Tuple.second indexedTextItem).id == textId) indexedTextItems
                        |> List.map
                            (\indexedTextItem ->
                                Tuple.mapSecond (\textItem -> { textItem | rating = rating }) indexedTextItem
                            )

                updatedTextItem =
                    List.filter (\indexedTextItem -> (Tuple.second indexedTextItem).id == textId) updatedTextItemRating
                        |> List.map
                            (\indexedTextItem ->
                                let
                                    prevVote =
                                        (Tuple.second indexedTextItem).vote
                                in
                                case prevVote of
                                    Up ->
                                        case vote of
                                            Up ->
                                                Tuple.mapSecond (\textItem -> { textItem | vote = None }) indexedTextItem

                                            None ->
                                                Tuple.mapSecond (\textItem -> { textItem | vote = Up }) indexedTextItem

                                            Down ->
                                                Tuple.mapSecond (\textItem -> { textItem | vote = Down }) indexedTextItem

                                    None ->
                                        case vote of
                                            Up ->
                                                Tuple.mapSecond (\textItem -> { textItem | vote = Up }) indexedTextItem

                                            None ->
                                                indexedTextItem

                                            Down ->
                                                Tuple.mapSecond (\textItem -> { textItem | vote = Down }) indexedTextItem

                                    Down ->
                                        case vote of
                                            Up ->
                                                Tuple.mapSecond (\textItem -> { textItem | vote = Up }) indexedTextItem

                                            None ->
                                                Tuple.mapSecond (\textItem -> { textItem | vote = Down }) indexedTextItem

                                            Down ->
                                                Tuple.mapSecond (\textItem -> { textItem | vote = None }) indexedTextItem
                            )

                updatedTextItems =
                    List.filter (\indexedTextItem -> (Tuple.second indexedTextItem).id /= textId) indexedTextItems
                        |> List.append updatedTextItem
                        |> List.sortBy Tuple.first
                        |> List.map Tuple.second
            in
            ( SafeModel
                { model
                    | results = updatedTextItems
                }
            , Cmd.none
            )

        GotVote (Err error) ->
            case error of
                Http.Detailed.BadStatus metadata body ->
                    if metadata.statusCode == 403 then
                        ( SafeModel model
                        , Api.logout ()
                        )

                    else
                        ( SafeModel { model | errorMessage = Just "An error occurred.  Please contact an administrator." }
                        , Cmd.none
                        )

                _ ->
                    ( SafeModel { model | errorMessage = Just "An error occurred.  Please contact an administrator." }
                    , Cmd.none
                    )

        Logout ->
            ( SafeModel model
            , Api.logout ()
            )


updateResults : Session -> Config -> TextSearch -> Cmd Msg
updateResults session config textSearch =
    let
        filterParams =
            Text.Search.filterParams textSearch

        queryParameters =
            List.map Endpoint.filterToStringQueryParam filterParams
    in
    if List.length filterParams > 0 then
        Api.getDetailed
            (Endpoint.textSearch (Config.restApiUrl config) queryParameters)
            (Session.cred session)
            TextSearch
            Text.Decode.textListDecoder

    else
        Cmd.none


updateRating : Session -> Config -> Vote -> Int -> TextSearch -> Cmd Msg
updateRating session config vote textId textSearch =
    let
        filterParams =
            Text.Search.filterParams textSearch

        queryParameters =
            List.map Endpoint.filterToStringQueryParam filterParams
    in
    Api.patchDetailed
        (Endpoint.voteText (Config.restApiUrl config) textId queryParameters)
        (Session.cred session)
        (Http.jsonBody (Vote.encode vote))
        GotVote
        voteResponseDecoder



-- DECODE


voteResponseDecoder : Json.Decode.Decoder VoteResponse
voteResponseDecoder =
    Json.Decode.succeed VoteResponse
        |> required "textId" Json.Decode.int
        |> required "vote" Vote.decoder
        |> required "rating" Json.Decode.int


-- VIEW


view : SafeModel -> Document Msg
view (SafeModel model) =
    { title = "Search Texts"
    , body =
        [ div []
            [ viewContent (SafeModel model)
            ]
        ]
    }


viewContent : SafeModel -> Html Msg
viewContent (SafeModel model) =
    div [ id "text_search" ] <|
        (if model.showHelp then
            [ viewHelpMessage ]

         else
            []
        )
            ++ [ viewSearchFilters (SafeModel model)
               , viewSearchResults model.timezone model.results
               , viewSearchFooter (SafeModel model)
               ]


viewHelpMessage : Html Msg
viewHelpMessage =
    div [ id "text-search-welcome-message" ]
        [ div []
            [ Html.text
                """Welcome! Use this page to find texts for your proficiency level and on topics that are of interest to you. 
                   Read the hints on this page, and next read the 
                """

            -- N.B. the demo text is text 19
            , a [ href (Route.toString (Route.Text__Id_Int { id = 19 })) ] [ Html.text "Demo Text" ]
            , Html.text " to learn how to use the text reader."
            ]
        ]


viewSearchFilters : SafeModel -> Html Msg
viewSearchFilters (SafeModel model) =
    div [ id "text_search_filters" ]
        [ div [ id "text_search_filters_label" ] [ Html.text "Filters" ]
        , div [ class "search_filter" ] <|
            [ div [ class "search_filter_title" ] [ Html.text "Difficulty" ]
            , div [] (viewDifficulties (Text.Search.difficultySearch model.textSearch))
            ]
                ++ viewDifficultyFilterHint (SafeModel model)
        , div [ class "search_filter" ]
            [ div [ class "search_filter_title" ] [ Html.text "Tags" ]
            , div [] <|
                [ viewTags (Text.Search.tagSearch model.textSearch) ]
                    ++ viewTopicFilterHint (SafeModel model)
            ]
        , div [ class "search_filter" ] <|
            [ div [ class "search_filter_title" ] [ Html.text "Read Status" ]
            , div [] (viewStatuses (Text.Search.statusSearch model.textSearch))
            ]
                ++ viewStatusFilterHint (SafeModel model)
        ]


viewSearchResults : Time.Zone -> List Text.Model.TextListItem -> Html Msg
viewSearchResults timezone textListItems =
    let
        viewSearchResult textItem =
            let
                textRating =
                    String.fromInt textItem.rating

                hasRead =
                    case textItem.last_read_dt of
                        Just _ ->
                            "vote-enabled"

                        Nothing ->
                            "vote-disabled"

                upArrow =
                    case textItem.last_read_dt of
                        Just _ ->
                            case textItem.vote of
                                Up ->
                                    "arrow_upward_enabled.svg"

                                -- turn down grey and up orange
                                None ->
                                    "arrow_upward.svg"

                                -- then both stay black
                                Down ->
                                    "arrow_upward_disabled.svg"

                        -- turn up grey and down blue
                        Nothing ->
                            "arrow_upward_disabled.svg"

                downArrow =
                    case textItem.last_read_dt of
                        Just _ ->
                            case textItem.vote of
                                Up ->
                                    "arrow_downward_disabled.svg"

                                -- turn down grey and up orange
                                None ->
                                    "arrow_downward.svg"

                                -- then both stay black
                                Down ->
                                    "arrow_downward_enabled.svg"

                        -- turn up grey and down blue
                        Nothing ->
                            "arrow_downward_disabled.svg"

                difficultyCategory =
                    case
                        List.head <|
                            List.filter
                                (\difficulty ->
                                    Tuple.first difficulty == textItem.difficulty
                                )
                                Shared.difficulties
                    of
                        Just difficulty ->
                            Tuple.second difficulty

                        Nothing ->
                            ""

                commaDelimitedTags =
                    case textItem.tags of
                        Just tags ->
                            String.join ", " tags

                        Nothing ->
                            ""

                sectionsCompleted =
                    case textItem.text_sections_complete of
                        Just sectionsComplete ->
                            String.fromInt sectionsComplete ++ " / " ++ String.fromInt textItem.text_section_count

                        Nothing ->
                            "0 / " ++ String.fromInt textItem.text_section_count

                lastRead =
                    case textItem.last_read_dt of
                        Just dt ->
                            Utils.Date.monthDayYearFormat timezone dt

                        Nothing ->
                            ""

                questionsCorrect =
                    case textItem.questions_correct of
                        Just correct ->
                            String.fromInt (Tuple.first correct) ++ " out of " ++ String.fromInt (Tuple.second correct)

                        Nothing ->
                            "None attempted"
            in
            div [ class "search_result" ]
                [ div [ class "voting-mechanism" ]
                    [ div [ class "upvote" ] [ Html.span [ class hasRead, onClick (Vote Up textItem.id) ] [ Html.img [ attribute "src" ("/public/img/" ++ upArrow), attribute "height" "28px", attribute "width" "28px" ] [] ] ]
                    , div [ class "result_item_title" ]
                        [ Html.text textRating ]
                    , div [ class "downvote" ] [ Html.span [ class hasRead, onClick (Vote Down textItem.id) ] [ Html.img [ attribute "src" ("/public/img/" ++ downArrow), attribute "height" "28px", attribute "width" "28px" ] [] ] ]
                    ]
                , div [ class "result_item" ]
                    [ div [ class "result_item_title" ]
                        [ Html.a
                            [ attribute "href" (Route.toString (Route.Text__Id_Int { id = textItem.id })) ]
                            [ Html.text textItem.title ]
                        ]
                    , div [ class "sub_description" ] [ Html.text "Title" ]
                    ]
                , div [ class "result_item" ]
                    [ div [ class "result_item_title" ] [ Html.text difficultyCategory ]
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
    if List.isEmpty textListItems then
        div [] []

    else
        div [ id "text_search_results" ] (List.map viewSearchResult textListItems)


viewSearchFooter : SafeModel -> Html Msg
viewSearchFooter (SafeModel model) =
    let
        entries =
            if List.length model.results == 1 then
                "entry"

            else
                "entries"
    in
    div [ id "footer_items" ]
        [ div [ id "footer", class "message" ]
            [ case model.errorMessage of
                Just message ->
                    Html.text message

                Nothing ->
                    if List.isEmpty model.results then
                        viewLoader

                    else
                        Html.text <|
                            String.join " " <|
                                [ "Showing"
                                , String.fromInt (List.length model.results)
                                , entries
                                ]
            ]
        ]


viewLoader : Html Msg
viewLoader =
    div [ class "loader" ]
        [ div [ class "loader-dot" ] []
        , div [ class "loader-dot" ] []
        , div [ class "loader-dot" ] []
        , div [ class "loader-dot" ] []
        ]


viewTags : TagSearch -> Html Msg
viewTags tagSearch =
    let
        tags =
            Text.Search.Tag.optionsToDict tagSearch

        viewTag tagSearchOption =
            let
                selected =
                    Text.Search.Option.selected tagSearchOption

                tagValue =
                    Text.Search.Option.value tagSearchOption

                tagLabel =
                    Text.Search.Option.label tagSearchOption
            in
            div
                [ onClick (SelectTag tagValue (not selected))
                , classList
                    [ ( "text_tag", True )
                    , ( "text_tag_selected", selected )
                    ]
                ]
                [ Html.text tagLabel
                ]
    in
    div [ id "text_tags" ]
        [ div [ class "text_tags" ] <|
            (Dict.values tags
                |> List.filter (\tag -> Text.Search.Option.label tag /= "Hidden")
                |> List.map viewTag
            )
        ]


viewDifficulties : DifficultySearch -> List (Html Msg)
viewDifficulties difficultySearch =
    let
        difficulties =
            Text.Search.Difficulty.options difficultySearch

        viewDifficulty difficultySearchOption =
            let
                selected =
                    Text.Search.Option.selected difficultySearchOption

                value =
                    Text.Search.Option.value difficultySearchOption

                label =
                    Text.Search.Option.label difficultySearchOption
            in
            div
                [ classList [ ( "difficulty_option", True ), ( "difficulty_option_selected", selected ) ]
                , onClick (AddDifficulty value (not selected))
                ]
                [ Html.text label
                ]
    in
    List.map viewDifficulty difficulties


viewStatuses : TextReadStatusSearch -> List (Html Msg)
viewStatuses statusSearch =
    let
        statuses =
            Text.Search.ReadingStatus.options statusSearch

        viewStatus ( value, statusOption ) =
            let
                selected =
                    Text.Search.Option.selected statusOption

                label =
                    Text.Search.Option.label statusOption

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
    List.map viewStatus <| List.map (\option -> ( Text.Search.Option.value option, option )) statuses



-- HINTS


viewTopicFilterHint : SafeModel -> List (Html Msg)
viewTopicFilterHint (SafeModel model) =
    let
        topicFilterHelp =
            TextSearch.Help.topic_filter_help

        hintAttributes =
            { id = TextSearch.Help.popupToID topicFilterHelp
            , visible = TextSearch.Help.isVisible model.help topicFilterHelp
            , text = TextSearch.Help.helpMsg topicFilterHelp
            , cancel_event = onClick (CloseHint topicFilterHelp)
            , next_event = onClick NextHint
            , prev_event = onClick PreviousHint
            , addl_attributes = [ class "difficulty_filter_hint" ]
            , arrow_placement = ArrowUp ArrowLeft
            }
    in
    if model.showHelp then
        [ Help.View.view_hint_overlay hintAttributes
        ]

    else
        []


viewDifficultyFilterHint : SafeModel -> List (Html Msg)
viewDifficultyFilterHint (SafeModel model) =
    let
        difficultyFilterHelp =
            TextSearch.Help.difficulty_filter_help

        hintAttributes =
            { id = TextSearch.Help.popupToID difficultyFilterHelp
            , visible = TextSearch.Help.isVisible model.help difficultyFilterHelp
            , text = TextSearch.Help.helpMsg difficultyFilterHelp
            , cancel_event = onClick (CloseHint difficultyFilterHelp)
            , next_event = onClick NextHint
            , prev_event = onClick PreviousHint
            , addl_attributes = [ class "difficulty_filter_hint" ]
            , arrow_placement = ArrowUp ArrowLeft
            }
    in
    if model.showHelp then
        [ Help.View.view_hint_overlay hintAttributes
        ]

    else
        []


viewStatusFilterHint : SafeModel -> List (Html Msg)
viewStatusFilterHint (SafeModel model) =
    let
        statusFilterHelp =
            TextSearch.Help.status_filter_help

        hintAttributes =
            { id = TextSearch.Help.popupToID statusFilterHelp
            , visible = TextSearch.Help.isVisible model.help statusFilterHelp
            , text = TextSearch.Help.helpMsg statusFilterHelp
            , cancel_event = onClick (CloseHint statusFilterHelp)
            , next_event = onClick NextHint
            , prev_event = onClick PreviousHint
            , addl_attributes = [ class "status_filter_hint" ]
            , arrow_placement = ArrowUp ArrowLeft
            }
    in
    if model.showHelp then
        [ Help.View.view_hint_overlay hintAttributes
        ]

    else
        []



-- SHARED


save : SafeModel -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> SafeModel -> ( SafeModel, Cmd Msg )
load shared (SafeModel model) =
    ( SafeModel
        { model
            | timezone = shared.timezone
            , profile = shared.profile
        }
    , case shared.profile of
        User.Profile.Student student_profile ->
            case StudentProfile.studentDifficultyPreference student_profile of
                Just difficulty ->
                    Task.perform (\_ -> AddDifficulty (Tuple.first difficulty) True) (Task.succeed Nothing)

                Nothing ->
                    Cmd.none

        _ ->
            Cmd.none
    )


subscriptions : SafeModel -> Sub Msg
subscriptions (SafeModel model) =
    Sub.none
