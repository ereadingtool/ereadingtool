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
import Help.View exposing (ArrowPlacement(..), ArrowPosition(..), view_hint_overlay)
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, href, id, rowspan)
import Html.Events exposing (onClick, onInput)
import Html.Parser
import Html.Parser.Util
import Http exposing (..)
import Json.Decode as Decode exposing (Decoder)
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
import User.Student.Performance.Report as PerformanceReport exposing (PerformanceMetrics, PerformanceReport)
import User.Student.Profile as StudentProfile exposing (StudentProfile, performanceReport)
import User.Student.Profile.Help as Help exposing (StudentHelp)
import User.Student.Resource as StudentResource
import Utils
import Viewer exposing (Viewer)
import Views


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
        , flashcards : Maybe (List String)
        , editing : Dict String Bool
        , errorMessage : String
        , help : Help.StudentProfileHelp
        , usernameValidation : UsernameValidation
        , errors : Dict String String
        }


init : Shared.Model -> Url Params -> ( SafeModel, Cmd Msg )
init shared { params } =
    let
        help =
            Help.init
    in
    ( SafeModel
        { session = shared.session
        , config = shared.config
        , navKey = shared.key
        , profile = Profile.toStudentProfile shared.profile
        , consentedToResearch = shared.researchConsent
        , flashcards = Nothing
        , editing = Dict.empty
        , usernameValidation = { username = Nothing, valid = Nothing, msg = Nothing }
        , help = help
        , errorMessage = ""
        , errors = Dict.empty
        }
    , Help.scrollToFirstMsg help
    )



-- UPDATE


type Msg
    = GotProfile (Result Error StudentProfile)
      -- username
    | ToggleUsernameUpdate
    | UpdateUsername String
    | GotUsernameValidation (Result Error UsernameValidation)
    | SubmitUsernameUpdate
    | CancelUsernameUpdate
      -- preferred difficulty
    | SubmitDifficulty String
      -- research consent
    | ToggleResearchConsent
    | GotConsent (Result Error StudentConsentResp)
      -- help messages
    | ToggleShowHelp
    | CloseHint StudentHelp
    | PreviousHint
    | NextHint
      -- site-wide messages
    | Logout


update : Msg -> SafeModel -> ( SafeModel, Cmd Msg )
update msg (SafeModel model) =
    case msg of
        GotProfile (Ok studentProfile) ->
            ( SafeModel { model | profile = studentProfile, editing = Dict.fromList [] }
            , Cmd.none
            )

        GotProfile (Err err) ->
            case err of
                Http.BadStatus resp ->
                    ( SafeModel { model | errorMessage = "Could not update student profile" }
                    , Cmd.none
                    )

                Http.BadBody _ ->
                    ( SafeModel { model | errorMessage = "Could not update student profile" }
                    , Cmd.none
                    )

                _ ->
                    ( SafeModel { model | errorMessage = "Could not update student profile" }
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

        GotUsernameValidation (Ok usernameValidation) ->
            ( SafeModel { model | usernameValidation = usernameValidation }, Cmd.none )

        GotUsernameValidation (Err error) ->
            case error of
                Http.BadStatus resp ->
                    ( SafeModel model, Cmd.none )

                Http.BadBody _ ->
                    ( SafeModel model, Cmd.none )

                _ ->
                    ( SafeModel model, Cmd.none )

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

        ToggleResearchConsent ->
            ( SafeModel model
            , putResearchConsent
                model.session
                model.config
                model.profile
                (not model.consentedToResearch)
            )

        GotConsent (Ok resp) ->
            ( SafeModel { model | consentedToResearch = resp.consented }, Cmd.none )

        GotConsent (Err err) ->
            case err of
                Http.BadStatus resp ->
                    ( SafeModel { model | errorMessage = "Could not update research consent" }
                    , Cmd.none
                    )

                Http.BadBody _ ->
                    ( SafeModel { model | errorMessage = "Could not update research consent" }
                    , Cmd.none
                    )

                _ ->
                    ( SafeModel { model | errorMessage = "Could not update research consent" }
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

        Logout ->
            ( SafeModel model
            , Api.logout ()
            )


putProfile :
    Session
    -> Config
    -> StudentProfile
    -> Cmd Msg
putProfile session config profile =
    case StudentProfile.studentID profile of
        Just studentId ->
            Api.put
                (Endpoint.studentProfile (Config.restApiUrl config) studentId)
                (Session.cred session)
                (Http.jsonBody (profileEncoder profile))
                GotProfile
                StudentProfile.decoder

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
            Api.put
                (Endpoint.consentToResearch (Config.restApiUrl config) studentId)
                (Session.cred session)
                (Http.jsonBody (consentEncoder consent))
                GotConsent
                studentConsentRespDecoder

        Nothing ->
            Cmd.none


validateUsername :
    Session
    -> Config
    -> String
    -> Cmd Msg
validateUsername session config name =
    Api.post
        (Endpoint.validateUsername (Config.restApiUrl config))
        (Session.cred session)
        (Http.jsonBody (usernameEncoder name))
        GotUsernameValidation
        usernameValidationDecoder


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



-- VIEW


view : SafeModel -> Document Msg
view (SafeModel model) =
    { title = "Student Profile"
    , body =
        [ div []
            [ viewContent (SafeModel model)
            , Views.view_footer
            ]
        ]
    }


viewContent : SafeModel -> Html Msg
viewContent (SafeModel model) =
    div [ classList [ ( "profile", True ) ] ]
        [ div [ class "profile-title" ]
            [ Html.text "Student Profile" ]
        , div [ classList [ ( "profile_items", True ) ] ]
            [ viewPreferredDifficulty (SafeModel model)
            , viewUsername (SafeModel model)
            , viewUserEmail (SafeModel model)
            , viewStudentPerformance (SafeModel model)
            , viewFeedbackLinks
            , viewFlashcards (SafeModel model)
            , viewResearchConsent (SafeModel model)
            , viewShowHelp (SafeModel model)
            , if not (String.isEmpty model.errorMessage) then
                span [ attribute "class" "error" ] [ Html.text "error: ", Html.text model.errorMessage ]

              else
                Html.text ""
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
            [ span [ class "cursor", onClick CancelUsernameUpdate ] [ Html.text "Cancel" ]
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
    let
        performanceReport =
            StudentProfile.performanceReport model.profile
    in
    div [ class "performance" ] <|
        viewPerformanceHint (SafeModel model)
            ++ [ span [ class "profile_item_title" ] [ Html.text "My Performance: " ]
               , span [ class "profile_item_value" ]
                    [ div [ class "performance_report" ]
                        [ viewPerformanceReportTable (StudentProfile.performanceReport model.profile)
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


viewPerformanceReportTable : PerformanceReport -> Html Msg
viewPerformanceReportTable performanceReport =
    div []
        [ table [] <|
            [ tr []
                [ th [] [ text "Level" ]
                , th [] [ text "Time Period" ]
                , th [] [ text "Number of Texts Read" ]
                , th [] [ text "Percent Correct" ]
                ]
            ]
                ++ viewPerformanceLevelRow "All" performanceReport.all
                ++ viewPerformanceLevelRow "Intermediate-Mid" performanceReport.intermediateMid
                ++ viewPerformanceLevelRow "Intermediate-High" performanceReport.intermediateHigh
                ++ viewPerformanceLevelRow "Advanced-Low" performanceReport.advancedLow
                ++ viewPerformanceLevelRow "Advanced-Mid" performanceReport.advancedMid
        ]


viewPerformanceLevelRow : String -> Dict String PerformanceMetrics -> List (Html Msg)
viewPerformanceLevelRow level metricsDict =
    let
        cumulative =
            PerformanceReport.metrics "cumulative" metricsDict

        currentMonth =
            PerformanceReport.metrics "current_month" metricsDict

        pastMonth =
            PerformanceReport.metrics "past_month" metricsDict
    in
    [ tr []
        [ td [ rowspan 4 ] [ text level ]
        ]
    , tr []
        [ td [] [ text "Cumulative" ]
        , td [] [ viewTextsReadCell cumulative ]
        , td [] [ viewPercentCorrectCell cumulative ]
        ]
    , tr []
        [ td [] [ text "Current Month" ]
        , td [] [ viewTextsReadCell currentMonth ]
        , td [] [ viewPercentCorrectCell currentMonth ]
        ]
    , tr []
        [ td [] [ text "Past Month" ]
        , td [] [ viewTextsReadCell pastMonth ]
        , td [] [ viewPercentCorrectCell pastMonth ]
        ]
    ]


viewTextsReadCell : PerformanceMetrics -> Html Msg
viewTextsReadCell metrics =
    text <|
        String.join " " <|
            [ String.fromInt metrics.textsComplete
            , "out of"
            , String.fromInt metrics.totalTexts
            ]


viewPercentCorrectCell : PerformanceMetrics -> Html Msg
viewPercentCorrectCell metrics =
    text <|
        String.fromFloat metrics.percentCorrect
            ++ "%"


viewFlashcards : SafeModel -> Html Msg
viewFlashcards (SafeModel model) =
    div [ id "flashcards", class "profile_item" ]
        [ span [ class "profile_item_title" ] [ Html.text "Flashcard Words" ]
        , span [ class "profile_item_value" ]
            [ div []
                (case model.flashcards of
                    Just words ->
                        List.map (\word -> div [] [ span [] [ Html.text word ] ]) words

                    Nothing ->
                        []
                )
            ]
        ]


viewFeedbackLinks : Html Msg
viewFeedbackLinks =
    div [ class "feedback" ]
        [ span [ class "profile_item_title" ] [ Html.text "Contact" ]
        , span [ class "profile_item_value" ]
            [ div []
                [ Html.a [ attribute "href" "https://goo.gl/forms/Wn5wWVHdmBKOxsFt2" ]
                    [ Html.text "Report a problem"
                    ]
                ]
            , div []
                [ Html.a [ attribute "href" "https://goo.gl/forms/z5BKx36xBJR7XqQY2" ]
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
        [ span [ class "profile_item_title" ] [ Html.text "Research Consent" ]
        , span []
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
        , span [ class "value" ]
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


viewShowHelp : SafeModel -> Html Msg
viewShowHelp (SafeModel model) =
    div [] <|
        [ div [ id "show-help" ]
            [ span [ class "profile_item_title" ] [ Html.text "Show Hints" ]
            , span []
                [ Html.text """
          Turn the site tutorials on or off.
          """
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
        ]
            ++ viewShowHelpHint (SafeModel model)



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


viewSearchTextsHint : SafeModel -> List (Html Msg)
viewSearchTextsHint (SafeModel model) =
    let
        searchTextsHelp =
            Help.searchTextsHelp

        hintAttributes =
            { id = Help.popupToOverlayID searchTextsHelp
            , visible = Help.isVisible model.help searchTextsHelp
            , text = Help.helpMsg searchTextsHelp
            , cancel_event = onClick (CloseHint searchTextsHelp)
            , next_event = onClick NextHint
            , prev_event = onClick PreviousHint
            , addl_attributes = [ id (Help.helpID model.help searchTextsHelp) ]
            , arrow_placement = ArrowUp ArrowLeft
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
                  , Markdown.toHtml [] """**Texts at the Intermediate Mid level** tend to be short public announcements,
        selections from personal correspondence, clearly organized texts in very recognizable genres with clear
        structure (like a biography, public opinion survey, etc.). Questions will focus on your ability to recognize
        the main ideas of the text. Typically, students in second year Russian can attempt texts at this level. """
                  )
                , ( "intermediate_high"
                  , Markdown.toHtml [] """**Texts at the Intermediate High level** will tend to be several paragraphs in length,
        touching on topics of personal and/or public interest.  The texts will tell a story, give a description or
        explanation of something related to the topic. At the intermediate high level, you may be able to get the main
        idea of the text, but the supporting details may be elusive. Typically, students in third year Russian can
        attempt texts at this level."""
                  )
                , ( "advanced_low"
                  , Markdown.toHtml [] """**Texts at the Advanced Low level** will be multiple paragraphs in length, touching on
        topics of public interest. They may be excerpts from straightforward literary texts, from newspapers relating
        the circumstances related to an event of public interest.  Texts may related to present, past or future time
        frames. Advanced Low texts will show a strong degree of internal cohesion and organization.  The paragraphs
        cannot be rearranged without doing damage to the comprehensibility of the passage. At the Advanced low level,
        you should be able to understand the main ideas of the passage as well as the supporting details.
        Readers at the Advanced Low level can efficiently balance the use of background knowledge WITH linguistic
        knowledge to determine the meaning of a text, although complicated word order may interfere with the reader’s
        comprehension. Typically, students in fourth year Russian can attempt these texts. """
                  )
                , ( "advanced_mid"
                  , Markdown.toHtml [] """**Texts at the Advanced Mid level** will be even longer than at the Advanced Low level.
        They will address issues of public interest, and they may contain narratives, descriptions, explanations, and
        some argumentation, laying out and justifying a particular point of view. At the Advanced Mid level, texts
        contain cultural references that are important for following the author’s point of view and argumentation.
        Texts may contain unusual plot twists and unexpected turns of events, but they do not confuse readers because
        readers have a strong command of the vocabulary, syntax, rhetorical devices that organize texts. Readers at the
        Advanced Mid level can handle the main ideas and the factual details of texts. Typically, strong students in
        4th year Russian or in 5th year Russian can attempt texts at this level. """
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
    }


load : Shared.Model -> SafeModel -> ( SafeModel, Cmd Msg )
load shared (SafeModel model) =
    ( SafeModel
        { model
            | profile = Profile.toStudentProfile shared.profile
            , consentedToResearch = shared.researchConsent
        }
    , Cmd.none
    )


subscriptions : SafeModel -> Sub Msg
subscriptions (SafeModel model) =
    Sub.none
