module Pages.Profile.Student exposing
    ( Model
    , Msg
    , Params
    , page
    )

import Api
import Api.Config as Config exposing (Config)
import Api.Endpoint as Endpoint
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Help.View exposing (ArrowPlacement(..), ArrowPosition(..))
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, href, id)
import Html.Events exposing (onClick, onInput)
import Http exposing (..)
import Http.Detailed
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode exposing (Value)
import Markdown
import OrderedDict
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Text.Model as Text
import User.Profile as Profile
import User.Student.Performance.Report as PerformanceReport exposing (Tab(..))
import User.Student.Profile as StudentProfile exposing (StudentProfile)
import User.Student.Profile.Help as Help exposing (StudentHelp)
import User.Student.Resource as StudentResource


page : Page Params Model Msg
page =
    Page.protectedStudentApplication
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , save = save
        , load = load
        }


type alias UsernameValidation =
    { username : Maybe StudentResource.StudentUsername
    , valid : Maybe Bool
    , msg : Maybe String
    }


type alias StudentConsentResp =
    { consented : Bool }


type alias StudentConnectResp =
    { connected : Bool }

-- INIT


type alias Params =
    ()


type alias Model =
    Maybe SafeModel


type SafeModel
    = SafeModel
        { session : Session
        , config : Config
        , navKey : Key
        , profile : StudentProfile
        , consentedToResearch : Bool
        , connectedToDashboard : Bool
        , flashcards : Maybe (List String)
        , editing : Dict String Bool
        , usernameValidation : UsernameValidation
        , performanceReportTab : PerformanceReport.Tab
        , help : Help.StudentProfileHelp
        , errorMessage : String
        , errors : Dict String String
        }


init : Shared.Model -> Url Params -> ( SafeModel, Cmd Msg )
init shared { params } =
    let
        help =
            Help.init

        studentProfile =
            Profile.toStudentProfile shared.profile
    in
    ( SafeModel
        { session = shared.session
        , config = shared.config
        , navKey = shared.key
        , profile = studentProfile
        , consentedToResearch = shared.researchConsent
        , connectedToDashboard = shared.dashboardConnect
        , flashcards = Nothing
        , editing = Dict.empty
        , usernameValidation = { username = Nothing, valid = Nothing, msg = Nothing }
        , performanceReportTab = Completion
        , help = help
        , errorMessage = ""
        , errors = Dict.empty
        }
    , Cmd.batch
        [ Help.scrollToFirstMsg help
        , Api.websocketDisconnectAll
        , case StudentProfile.studentID studentProfile of
            Just id ->
                -- in the current implementation, a default profile with an ID of 0 is used.
                -- check that to avoid requesting the profile on page refresh
                if id /= 0 then
                    getStudentProfile
                        shared.session
                        shared.config
                        (Profile.toStudentProfile shared.profile)

                else
                    Cmd.none

            Nothing ->
                Cmd.none
        ]
    )



-- UPDATE


type Msg
    = GotProfile (Result (Http.Detailed.Error String) ( Http.Metadata, StudentProfile ))
      -- username
    | ToggleUsernameUpdate
    | UpdateUsername String
    | GotUsernameValidation (Result (Http.Detailed.Error String) ( Http.Metadata, UsernameValidation ))
    | SubmitUsernameUpdate
    | CancelUsernameUpdate
      -- preferred difficulty
    | SubmitDifficulty String
      -- research consent
    | ToggleResearchConsent
    | GotResearchConsent (Result (Http.Detailed.Error String) ( Http.Metadata, StudentConsentResp ))
      -- dashboard connect
    | ToggleDashboardConnect
    | GotDashboardConnect (Result (Http.Detailed.Error String) ( Http.Metadata, StudentConnectResp ))
      -- help messages
    | ToggleShowHelp
    | CloseHint StudentHelp
    | PreviousHint
    | NextHint
      -- performance report
    | SelectReportTab PerformanceReport.Tab


update : Msg -> SafeModel -> ( SafeModel, Cmd Msg )
update msg (SafeModel model) =
    case msg of
        GotProfile (Ok ( metadata, studentProfile )) ->
            ( SafeModel { model | profile = studentProfile, editing = Dict.fromList [] }
            , Cmd.none
            )

        GotProfile (Err error) ->
            case error of
                Http.Detailed.BadStatus metadata body ->
                    if metadata.statusCode == 403 then
                        ( SafeModel model
                        , Api.logout ()
                        )

                    else
                        ( SafeModel { model | errors = errorBodyToDict body }
                        , Cmd.none
                        )

                _ ->
                    ( SafeModel
                        { model
                            | errors =
                                Dict.fromList [ ( "internal", "An internal error occured. Please contact the developers." ) ]
                        }
                    , Cmd.none
                    )

        ToggleUsernameUpdate ->
            ( toggleUsernameUpdate (SafeModel model), Cmd.none )

        UpdateUsername name ->
            let
                usernameValidation =
                    model.usernameValidation

                newUsernameValidation =
                    { usernameValidation | username = Just (StudentResource.toStudentUsername name) }
            in
            ( SafeModel { model | usernameValidation = newUsernameValidation }
            , validateUsername model.session model.config name
            )

        GotUsernameValidation (Ok ( metadata, usernameValidation )) ->
            ( SafeModel { model | usernameValidation = usernameValidation }
            , Cmd.none
            )

        GotUsernameValidation (Err error) ->
            case error of
                Http.Detailed.BadStatus metadata body ->
                    if metadata.statusCode == 403 then
                        ( SafeModel model
                        , Api.logout ()
                        )

                    else
                        ( SafeModel { model | errors = errorBodyToDict body }
                        , Cmd.none
                        )

                _ ->
                    ( SafeModel
                        { model
                            | errors =
                                Dict.fromList [ ( "internal", "An internal error occured. Please contact the developers." ) ]
                        }
                    , Cmd.none
                    )

        SubmitUsernameUpdate ->
            case model.usernameValidation.username of
                Just username ->
                    let
                        newProfile =
                            StudentProfile.setUserName model.profile username
                    in
                    ( SafeModel { model | profile = newProfile }
                        |> toggleUsernameUpdate
                    , putProfile model.session model.config newProfile
                    )

                Nothing ->
                    ( SafeModel model, Cmd.none )

        CancelUsernameUpdate ->
            ( toggleUsernameUpdate (SafeModel model), Cmd.none )

        SubmitDifficulty difficulty ->
            let
                newDifficultyPreference =
                    ( difficulty, difficulty )

                newProfile =
                    StudentProfile.setStudentDifficultyPreference model.profile newDifficultyPreference
            in
            ( SafeModel { model | profile = newProfile }
            , putProfile model.session model.config newProfile
            )

        ToggleDashboardConnect ->
            ( SafeModel model
            , putDashboardConnect
                model.session
                model.config
                model.profile
                (not model.connectedToDashboard)
            )

        ToggleResearchConsent ->
            ( SafeModel model
            , putResearchConsent
                model.session
                model.config
                model.profile
                (not model.consentedToResearch)
            )

        GotResearchConsent (Ok ( metadata, response )) ->
            ( SafeModel { model | consentedToResearch = response.consented }, Cmd.none )

        GotResearchConsent (Err error) ->
            case error of
                Http.Detailed.BadStatus metadata body ->
                    if metadata.statusCode == 403 then
                        ( SafeModel model
                        , Api.logout ()
                        )

                    else
                        ( SafeModel { model | errors = errorBodyToDict body }
                        , Cmd.none
                        )

                _ ->
                    ( SafeModel
                        { model
                            | errors =
                                Dict.fromList [ ( "internal", "An internal error occurred. Please contact the developers." ) ]
                        }
                    , Cmd.none
                    )

        GotDashboardConnect (Ok ( metadata, response )) ->
            ( SafeModel { model | connectedToDashboard = response.connected }, Cmd.none )

        GotDashboardConnect (Err error) ->
            case error of
                Http.Detailed.BadStatus metadata body ->
                    if metadata.statusCode == 403 then
                        ( SafeModel model
                        , Api.logout ()
                        )

                    else
                        ( SafeModel { model | errors = errorBodyToDict body }
                        , Cmd.none
                        )
                _ ->
                        ( SafeModel
                            { model
                                | errors =
                                    Dict.fromList [ ("internal", "An internal error occurred. Please contact the developers." ) ]
                            }
                        , Cmd.none
                        )


        ToggleShowHelp ->
            ( SafeModel { model | config = Config.mapShowHelp not model.config }
            , Api.toggleShowHelp <|
                Config.encodeShowHelp <|
                    not (Config.showHelp model.config)
            )

        CloseHint helpMessage ->
            ( SafeModel { model | help = Help.setVisible model.help helpMessage False }, Cmd.none )

        PreviousHint ->
            ( SafeModel { model | help = Help.prev model.help }, Help.scrollToPrevMsg model.help )

        NextHint ->
            ( SafeModel { model | help = Help.next model.help }, Help.scrollToNextMsg model.help )

        SelectReportTab reportTab ->
            ( SafeModel { model | performanceReportTab = reportTab }
            , Cmd.none
            )


getStudentProfile : Session -> Config -> StudentProfile -> Cmd Msg
getStudentProfile session config profile =
    case StudentProfile.studentID profile of
        Just studentId ->
            Api.getDetailed
                (Endpoint.studentProfile
                    (Config.restApiUrl config)
                    studentId
                )
                (Session.cred session)
                GotProfile
                StudentProfile.decoder

        Nothing ->
            Cmd.none


putProfile :
    Session
    -> Config
    -> StudentProfile
    -> Cmd Msg
putProfile session config profile =
    case StudentProfile.studentID profile of
        Just studentId ->
            Api.putDetailed
                (Endpoint.studentProfile (Config.restApiUrl config) studentId)
                (Session.cred session)
                (Http.jsonBody (profileEncoder profile))
                GotProfile
                StudentProfile.decoder

        Nothing ->
            Cmd.none


putDashboardConnect :
    Session
    -> Config
    -> StudentProfile
    -> Bool
    -> Cmd Msg
putDashboardConnect session config studentProfile connect =
    case StudentProfile.studentID studentProfile of
        Just studentId ->
            Api.putDetailed
                (Endpoint.connectToDashboard (Config.restApiUrl config) studentId)
                (Session.cred session)
                (Http.jsonBody (connectEncoder connect))
                GotDashboardConnect
                studentConnectRespDecoder

        Nothing ->
            Cmd.none


putResearchConsent :
    Session
    -> Config
    -> StudentProfile
    -> Bool
    -> Cmd Msg
putResearchConsent session config studentProfile consent =
    case StudentProfile.studentID studentProfile of
        Just studentId ->
            Api.putDetailed
                (Endpoint.consentToResearch (Config.restApiUrl config) studentId)
                (Session.cred session)
                (Http.jsonBody (consentEncoder consent))
                GotResearchConsent
                studentConsentRespDecoder

        Nothing ->
            Cmd.none


validateUsername :
    Session
    -> Config
    -> String
    -> Cmd Msg
validateUsername session config name =
    Api.postDetailed
        (Endpoint.validateUsername (Config.restApiUrl config))
        (Session.cred session)
        (Http.jsonBody (usernameEncoder name))
        GotUsernameValidation
        usernameValidationDecoder


errorBodyToDict : String -> Dict String String
errorBodyToDict body =
    case Decode.decodeString (Decode.dict Decode.string) body of
        Ok dict ->
            dict

        Err err ->
            Dict.fromList [ ( "internal", "An internal error occured. Please contact the developers." ) ]


toggleUsernameUpdate : SafeModel -> SafeModel
toggleUsernameUpdate (SafeModel model) =
    SafeModel
        { model
            | editing =
                if Dict.member "username" model.editing then
                    Dict.remove "username" model.editing

                else
                    Dict.insert "username" True model.editing
        }



-- ENCODE


profileEncoder : StudentProfile -> Value
profileEncoder studentProfile =
    let
        encodedPreference =
            case StudentProfile.studentDifficultyPreference studentProfile of
                Just difficulty ->
                    Encode.string (Tuple.first difficulty)

                Nothing ->
                    Encode.null

        username =
            case StudentProfile.studentUserName studentProfile of
                Just uname ->
                    Encode.string (StudentProfile.studentUserNameToString uname)

                Nothing ->
                    Encode.null
    in
    Encode.object [ ( "difficulty_preference", encodedPreference ), ( "username", username ) ]


usernameEncoder : String -> Value
usernameEncoder username =
    Encode.object [ ( "username", Encode.string username ) ]


consentEncoder : Bool -> Value
consentEncoder consented =
    Encode.object
        [ ( "consent_to_research", Encode.bool consented )
        ]


connectEncoder : Bool -> Value
connectEncoder connected =
    Encode.object
        [ ( "connected_to_dashboard", Encode.bool connected )
        ]

-- DECODE


usernameValidationDecoder : Decode.Decoder UsernameValidation
usernameValidationDecoder =
    Decode.succeed UsernameValidation
        |> required "username" (Decode.map (StudentResource.toStudentUsername >> Just) Decode.string)
        |> required "valid" (Decode.nullable Decode.bool)
        |> required "msg" (Decode.nullable Decode.string)


studentConsentRespDecoder : Decode.Decoder StudentConsentResp
studentConsentRespDecoder =
    Decode.map
        StudentConsentResp
        (Decode.field "consented" Decode.bool)


studentConnectRespDecoder : Decode.Decoder StudentConnectResp
studentConnectRespDecoder =
    Decode.map
        StudentConnectResp
        (Decode.field "connected" Decode.bool)

-- VIEW


view : SafeModel -> Document Msg
view (SafeModel model) =
    { title = "Student Profile"
    , body =
        [ div []
            [ viewContent (SafeModel model)
            ]
        ]
    }


viewContent : SafeModel -> Html Msg
viewContent (SafeModel model) =
    div [ classList [ ( "profile", True ) ] ] <|
        (if Config.showHelp model.config then
            [ viewWelcomeBanner ]

         else
            []
        )
            ++ [ div [ class "profile-title" ]
                    [ Html.text "Student Profile" ]
               , div [ classList [ ( "profile_items", True ) ] ]
                    [ viewPreferredDifficulty (SafeModel model)
                    , viewUsername (SafeModel model)
                    , viewUserEmail (SafeModel model)
                    , viewShowHelp (SafeModel model)
                    , viewStudentPerformance (SafeModel model)
                    , viewResearchConsent (SafeModel model)
                    , viewDashboardConnect (SafeModel model)
                    , viewMyWords (SafeModel model)
                    , viewFeedbackLinks
                    , if not (String.isEmpty model.errorMessage) then
                        span [ attribute "class" "error" ] [ Html.text "error: ", Html.text model.errorMessage ]

                      else
                        Html.text ""
                    ]
               ]


viewWelcomeBanner : Html Msg
viewWelcomeBanner =
    div [ id "profile-welcome-banner" ]
        [ div []
            [ Html.text "Welcome to the STAR! If you would like to start reading right away, select "
            , Html.b [] [ Html.text "Texts" ]
            , Html.text " from the menu above this message. "
            , Html.text "This site shows you hints to get you started. You can read through the hints or turn them off in the "
            , Html.b [] [ Html.text "Show Hints" ]
            , Html.text " section below. "
            , Html.text "For more details please see the "
            , Html.a [ href (Route.toString Route.Guide__GettingStarted) ] [ Html.text "Guide." ]
            ]
        ]


viewPreferredDifficulty : SafeModel -> Html Msg
viewPreferredDifficulty (SafeModel model) =
    div [ class "preferred_difficulty" ] <|
        viewDifficultyHint (SafeModel model)
            ++ [ span [ class "profile_item_title" ] [ Html.text "Preferred Difficulty" ]
               , span [ class "profile_item_value" ]
                    [ viewDifficulty (SafeModel model)
                    , viewPreferredDifficultyHint (StudentProfile.studentDifficultyPreference model.profile)
                    ]
               ]


viewDifficulty : SafeModel -> Html Msg
viewDifficulty (SafeModel model) =
    let
        pref =
            Tuple.first (Maybe.withDefault ( "", "" ) (StudentProfile.studentDifficultyPreference model.profile))
    in
    div []
        [ Html.select [ onInput SubmitDifficulty, class "difficulty-select" ]
            [ Html.optgroup []
                (List.map
                    (\( k, v ) ->
                        Html.option
                            (attribute "value" k
                                :: (if k == pref then
                                        [ attribute "selected" "" ]

                                    else
                                        []
                                   )
                            )
                            [ Html.text v ]
                    )
                    Shared.difficulties
                )
            ]
        ]


viewUsername : SafeModel -> Html Msg
viewUsername (SafeModel model) =
    let
        username =
            case StudentProfile.studentUserName model.profile of
                Just uname ->
                    StudentProfile.studentUserNameToString uname

                Nothing ->
                    ""

        usernameValidAttributes =
            case model.usernameValidation.valid of
                Just valid ->
                    if valid then
                        [ class "valid_username" ]

                    else
                        [ class "invalid_username" ]

                Nothing ->
                    []

        usernameMessages =
            case model.usernameValidation.msg of
                Just msg ->
                    [ div [] [ Html.text msg ] ]

                Nothing ->
                    []
    in
    div [ class "profile_item" ] <|
        viewUsernameHint (SafeModel model)
            ++ [ span [ class "profile_item_title" ] [ Html.text "Username" ]
               , if Dict.member "username" model.editing then
                    span [ class "profile_item_value" ] <|
                        [ Html.input
                            [ class "username_input"
                            , attribute "placeholder" "Username"
                            , attribute "value" username
                            , attribute "maxlength" "150"
                            , attribute "minlength" "8"
                            , onInput UpdateUsername
                            ]
                            []
                        , span usernameValidAttributes []
                        , div [ class "username_msg" ] usernameMessages
                        ]
                            ++ viewUsernameSubmit model.usernameValidation

                 else
                    span [ class "profile_item_value" ]
                        [ Html.text username
                        , div [ class "update_username", class "cursor", onClick ToggleUsernameUpdate ] [ Html.text "Update" ]
                        ]
               ]


viewUsernameSubmit : UsernameValidation -> List (Html Msg)
viewUsernameSubmit username =
    case username.valid of
        Just valid ->
            if valid then
                [ div [ class "username_submit" ]
                    [ span [ class "cursor", onClick SubmitUsernameUpdate ] [ Html.text "Submit" ]
                    , span [ class "cursor", onClick CancelUsernameUpdate ] [ Html.text "Cancel" ]
                    ]
                ]

            else
                []

        Nothing ->
            [ span
                [ class "cursor"
                , class "username-update-cancel"
                , onClick CancelUsernameUpdate
                ]
                [ Html.text "Cancel" ]
            ]


viewUserEmail : SafeModel -> Html Msg
viewUserEmail (SafeModel model) =
    div [ class "profile_item" ]
        [ span [ class "profile_item_title" ] [ Html.text "User E-Mail" ]
        , span [ class "profile_item_value" ]
            [ Html.text
                (StudentResource.studentEmailToString
                    (StudentProfile.studentEmail model.profile)
                )
            ]
        ]


viewStudentPerformance : SafeModel -> Html Msg
viewStudentPerformance (SafeModel model) =
    div [ class "performance" ] <|
        viewPerformanceHint (SafeModel model)
            ++ [ span [ class "profile_item_title" ] [ Html.text "My Performance: " ]
               , span [ class "profile_item_value" ]
                    [ div [ class "performance_report" ]
                        [ PerformanceReport.view
                            { performanceReport = StudentProfile.performanceReport model.profile
                            , selectedTab = model.performanceReportTab
                            , onSelectReport = SelectReportTab
                            }
                        ]
                    ]
               , div [ class "performance_download_link" ]
                    [ Html.a
                        [ attribute "href" <|
                            case StudentProfile.studentID model.profile of
                                Just id ->
                                    Api.performanceReportLink
                                        (Config.restApiUrl model.config)
                                        (Session.cred model.session)
                                        id

                                Nothing ->
                                    ""
                        ]
                        [ Html.text "Download the \"My Performance\" table as a PDF"
                        ]
                    ]
               ]


viewMyWords : SafeModel -> Html Msg
viewMyWords (SafeModel model) =
    div [ id "words", class "profile_item" ]
        [ span [ class "profile_item_title" ] [ Html.text "My Words" ]
        , span [ class "profile_item_value" ]
            [ div [ class "words-download-link" ]
                [ Html.a
                    [ attribute "href" <|
                        case StudentProfile.studentID model.profile of
                            Just id ->
                                Api.wordsCsvLink
                                    (Config.restApiUrl model.config)
                                    (Session.cred model.session)
                                    id

                            Nothing ->
                                ""
                    ]
                    [ Html.text "Download your words as a CSV file"
                    ]
                ]
            , div [ class "words-download-link" ]
                [ Html.a
                    [ attribute "href" <|
                        case StudentProfile.studentID model.profile of
                            Just id ->
                                Api.wordsPdfLink
                                    (Config.restApiUrl model.config)
                                    (Session.cred model.session)
                                    id

                            Nothing ->
                                ""
                    ]
                    [ Html.text "Download your words as a PDF"
                    ]
                ]
            ]
        ]


viewFeedbackLinks : Html Msg
viewFeedbackLinks =
    div [ class "feedback" ]
        [ span [ class "profile_item_title" ] [ Html.text "Contact" ]
        , span [ class "profile_item_value" ]
            [ div []
                [ Html.a [ attribute "href" "https://forms.gle/urBbUYr8AmbFeW9b8" ]
                    [ Html.text "Report a problem"
                    ]
                ]
            , div []
                [ Html.a [ attribute "href" "https://forms.gle/6SwVYNyCw95sNrVk8" ]
                    [ Html.text "Please give us feedback!"
                    ]
                ]
            ]
        ]


viewResearchConsent : SafeModel -> Html Msg
viewResearchConsent (SafeModel model) =
    let
        consented =
            model.consentedToResearch

        consentedTooltip =
            "You've consented to be a part of a research study."

        noConsentTooltip =
            "You have not consented to be a part of a research study."
    in
    div [ id "research_consent" ]
        [ div [ class "profile_item_title" ] [ Html.text "Research Consent" ]
        , div []
            [ Html.text """
          From time to time, there maybe research projects related to this site.
          To read about those projects and to review and sign consent forms,
          please go
         """
            , Html.a [ attribute "href" "https://sites.google.com/pdx.edu/star-russian/home" ]
                [ Html.text "here"
                ]
            , Html.text "."
            ]
        , div [ class "value" ]
            [ div
                [ classList [ ( "check-box", True ), ( "check-box-selected", consented ) ]
                , onClick ToggleResearchConsent
                , attribute "title"
                    (if consented then
                        consentedTooltip

                     else
                        noConsentTooltip
                    )
                ]
                []
            , div [ class "check-box-text" ] [ Html.text "I consent to research." ]
            ]
        ]


viewDashboardConnect : SafeModel -> Html Msg
viewDashboardConnect (SafeModel model) =
    let
        connected =
            model.connectedToDashboard

        connectedTooltip =
            "You're connected to the Flagship Connect dashboard."

        notConnectedTooltip =
            "You're not connected to the Flagship Connect dashboard."
    in
    div [ id "dashboard_connect" ]
        [ div [ class "profile_item_title" ] [ Html.text "Flagship Connect" ]
        , div []
            [ Html.text """
            By checking this box you acknowledge that relevant data will be sent 
            to the Flagship Connect dashboard. Be sure to use the same email as your
            Flagship Connect account.
            """
            ]
        , div [ class "value" ]
            [ div
                [ classList [ ( "check-box", True ), ( "check-box-selected", connected ) ]
                , onClick ToggleDashboardConnect
                , attribute "title"
                    (if connected then
                        connectedTooltip

                     else
                        notConnectedTooltip
                    )
                ]
                []
            , div [ class "check-box-text" ] [ Html.text "I authorize Flagship Connect." ]
            ]
        ]


viewShowHelp : SafeModel -> Html Msg
viewShowHelp (SafeModel model) =
    div [ class "show-help" ] <|
        div [ id "show-help" ]
            [ span [ class "profile_item_title" ] [ Html.text "Show Hints" ]
            , span []
                [ Html.text "Turn the site tutorials on or off."
                ]
            , span [ class "value" ] <|
                [ div
                    [ classList
                        [ ( "check-box", True )
                        , ( "check-box-selected", Config.showHelp model.config )
                        ]
                    , onClick ToggleShowHelp
                    ]
                    []
                , div [ class "check-box-text" ] [ Html.text "Show hints" ]
                ]
            ]
            :: viewShowHelpHint (SafeModel model)



-- HINTS


viewShowHelpHint : SafeModel -> List (Html Msg)
viewShowHelpHint (SafeModel model) =
    let
        showHintsHelp =
            Help.showHintsHelp

        hintAttributes =
            { id = Help.popupToOverlayID showHintsHelp
            , visible = Help.isVisible model.help showHintsHelp
            , text = Help.helpMsg showHintsHelp
            , cancel_event = onClick (CloseHint showHintsHelp)
            , next_event = onClick NextHint
            , prev_event = onClick PreviousHint
            , addl_attributes = [ id (Help.helpID model.help showHintsHelp) ]

            -- , arrow_placement = ArrowDown ArrowLeft
            , arrow_placement = ArrowUp ArrowLeft
            }
    in
    if Config.showHelp model.config then
        [ Help.View.view_hint_overlay hintAttributes
        ]

    else
        []


viewUsernameHint : SafeModel -> List (Html Msg)
viewUsernameHint (SafeModel model) =
    let
        usernameHelp =
            Help.usernameHelp

        hintAttributes =
            { id = Help.popupToOverlayID usernameHelp
            , visible = Help.isVisible model.help usernameHelp
            , text = Help.helpMsg usernameHelp
            , cancel_event = onClick (CloseHint usernameHelp)
            , next_event = onClick NextHint
            , prev_event = onClick PreviousHint
            , addl_attributes = [ id (Help.helpID model.help usernameHelp) ]
            , arrow_placement = ArrowDown ArrowLeft
            }
    in
    if Config.showHelp model.config then
        [ Help.View.view_hint_overlay hintAttributes
        ]

    else
        []


viewPerformanceHint : SafeModel -> List (Html Msg)
viewPerformanceHint (SafeModel model) =
    let
        performanceHelp =
            Help.myPerformanceHelp

        hintAttributes =
            { id = Help.popupToOverlayID performanceHelp
            , visible = Help.isVisible model.help performanceHelp
            , text = Help.helpMsg performanceHelp
            , cancel_event = onClick (CloseHint performanceHelp)
            , next_event = onClick NextHint
            , prev_event = onClick PreviousHint
            , addl_attributes = [ id (Help.helpID model.help performanceHelp) ]
            , arrow_placement = ArrowDown ArrowLeft
            }
    in
    if Config.showHelp model.config then
        [ Help.View.view_hint_overlay hintAttributes
        ]

    else
        []


viewDifficultyHint : SafeModel -> List (Html Msg)
viewDifficultyHint (SafeModel model) =
    let
        difficultyHelp =
            Help.preferredDifficultyHelp

        hintAttributes =
            { id = Help.popupToOverlayID difficultyHelp
            , visible = Help.isVisible model.help difficultyHelp
            , text = Help.helpMsg difficultyHelp
            , cancel_event = onClick (CloseHint difficultyHelp)
            , next_event = onClick NextHint
            , prev_event = onClick PreviousHint
            , addl_attributes = [ id (Help.helpID model.help difficultyHelp) ]
            , arrow_placement = ArrowDown ArrowLeft
            }
    in
    if Config.showHelp model.config then
        [ Help.View.view_hint_overlay hintAttributes
        ]

    else
        []


viewPreferredDifficultyHint : Maybe Text.TextDifficulty -> Html Msg
viewPreferredDifficultyHint text_difficulty =
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
            OrderedDict.fromList
                [ ( "intermediate_mid"
                  , Markdown.toHtml [] """**Texts at the Intermediate Mid level** tend to be short public announcements or very 
        brief news reports that are clearly organized. Questions will focus on your ability to recognize the main 
        ideas of the text. Typically, students in second-year Russian can attempt texts at this level."""
                  )
                , ( "intermediate_high"
                  , Markdown.toHtml [] """**Texts at the Intermediate High level** will tend to be several paragraphs in length, 
        touching on topics of personal and/or public interest. The texts will typically describe, explain or narrate
        some event or situation related to the topic. At the Intermediate High level, you may be able to get the main 
        idea of the text, but you might struggle with details.Typically, students in third-year and fourth-year Russian 
        can attempt texts at this level."""
                  )
                , ( "advanced_low"
                  , Markdown.toHtml [] """**Texts at the Advanced Low level** will be multiple paragraphs in length that report 
        and describe topics of public interest. At the Advanced Low level, you should be able to understand the main 
        ideas of the passage as well as the supporting details. Typically, strong students in fourth-year Russian can 
        attempt these texts."""
                  )
                , ( "advanced_mid"
                  , Markdown.toHtml [] """**Texts at the Advanced Mid level** will be even longer than at the Advanced Low level, 
        and they address issues of public interest, and they may contain some argumentation. Readers at the Advanced Mid 
        level have a very broad vocabulary and can comprehend the main ideas and the factual details of texts. Typically, 
        strong students beyond fourth-year Russian can attempt texts at this level."""
                  )
                ]

        default_list =
            List.map (\( _, v ) -> div [ class "difficulty_desc" ] [ v ]) (OrderedDict.toList difficulty_msgs)

        help_msg =
            case text_difficulty of
                Just difficulty ->
                    case OrderedDict.get (Tuple.first difficulty) difficulty_msgs of
                        Just difficulty_msg ->
                            div [] [ difficulty_msg ]

                        Nothing ->
                            div [] (Html.text default_msg :: default_list)

                Nothing ->
                    div [] (Html.text default_msg :: default_list)
    in
    div [ class "difficulty_descs" ]
        [ div [ class "text_readings_values" ] [ help_msg ]
        ]



-- SHARED


save : SafeModel -> Shared.Model -> Shared.Model
save (SafeModel model) shared =
    { shared
        | config = model.config
        , profile = Profile.fromStudentProfile model.profile
        , researchConsent = model.consentedToResearch
        , dashboardConnect = model.connectedToDashboard
    }


load : Shared.Model -> SafeModel -> ( SafeModel, Cmd Msg )
load shared (SafeModel model) =
    ( SafeModel
        { model
            | profile = Profile.toStudentProfile shared.profile
            , consentedToResearch = shared.researchConsent
            , connectedToDashboard = shared.dashboardConnect
        }
    , Cmd.none
    )


subscriptions : SafeModel -> Sub Msg
subscriptions (SafeModel model) =
    Sub.none
