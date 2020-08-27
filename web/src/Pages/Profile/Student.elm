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
import Html.Attributes exposing (attribute, class, classList, href, id)
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
import User.Student.Performance.Report as PerformanceReport exposing (PerformanceReport)
import User.Student.Profile as StudentProfile
    exposing
        ( StudentProfile(..)
        , StudentURIs(..)
        )
import User.Student.Profile.Help as Help exposing (StudentHelp)
import User.Student.Resource as StudentResource
import Utils
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
        , performanceReport : PerformanceReport
        , consentedToResearch : Bool
        , flashcards : Maybe (List String)
        , editing : Dict String Bool
        , errorMessage : String
        , welcome : Bool
        , help : Help.StudentProfileHelp
        , usernameValidation : UsernameValidation
        , errors : Dict String String
        }


fakeProfile : StudentProfile
fakeProfile =
    StudentProfile
        (Just 0)
        (Just (StudentResource.toStudentUsername "fake name"))
        (StudentResource.toStudentEmail "test@email.com")
        Nothing
        Shared.difficulties
        (StudentURIs
            (StudentResource.toStudentLogoutURI "")
            (StudentResource.toStudentProfileURI "")
        )


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
        , profile = fakeProfile
        , performanceReport = PerformanceReport.emptyPerformanceReport
        , consentedToResearch = False
        , flashcards = Nothing
        , editing = Dict.empty
        , usernameValidation = { username = Nothing, valid = Nothing, msg = Nothing }
        , welcome = True
        , help = help
        , errorMessage = ""
        , errors = Dict.empty
        }
    , Help.scrollToFirstMsg help
    )



-- UPDATE


type Msg
    = RetrieveStudentProfile (Result Error StudentProfile)
      -- preferred difficulty
    | UpdateDifficulty String
      -- username
    | ToggleUsernameUpdate
    | ToggleResearchConsent
    | ValidUsername (Result Error UsernameValidation)
    | UpdateUsername String
    | SubmitUsernameUpdate
    | CancelUsernameUpdate
      -- profile update submission
    | Submitted (Result Error StudentProfile)
    | SubmittedConsent (Result Error StudentConsentResp)
      -- help messages
    | CloseHint StudentHelp
    | PreviousHint
    | NextHint
      -- site-wide messages
    | Logout


update : Msg -> SafeModel -> ( SafeModel, Cmd Msg )
update msg (SafeModel model) =
    case msg of
        RetrieveStudentProfile (Ok profile) ->
            let
                usernameValidation =
                    model.usernameValidation

                newUsernameValidation =
                    { usernameValidation | username = StudentProfile.studentUserName profile }
            in
            ( SafeModel { model | profile = profile, usernameValidation = newUsernameValidation }
            , Cmd.none
            )

        -- handle user-friendly msgs
        RetrieveStudentProfile (Err _) ->
            ( SafeModel { model | errorMessage = "Error retrieving student profile!" }
            , Cmd.none
            )

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

        ValidUsername (Ok usernameValidation) ->
            ( SafeModel { model | usernameValidation = usernameValidation }, Cmd.none )

        ValidUsername (Err error) ->
            case error of
                Http.BadStatus resp ->
                    ( SafeModel model, Cmd.none )

                Http.BadBody _ ->
                    ( SafeModel model, Cmd.none )

                _ ->
                    ( SafeModel model, Cmd.none )

        UpdateDifficulty difficulty ->
            let
                newDifficultyPreference =
                    ( difficulty, difficulty )

                newProfile =
                    StudentProfile.setStudentDifficultyPreference model.profile newDifficultyPreference
            in
            ( SafeModel { model | profile = newProfile }
            , putProfile model.session model.config newProfile
            )

        ToggleUsernameUpdate ->
            ( toggleUsernameUpdate (SafeModel model), Cmd.none )

        ToggleResearchConsent ->
            ( SafeModel model
            , putResearchConsent
                model.session
                model.config
                model.profile
                (not model.consentedToResearch)
            )

        SubmitUsernameUpdate ->
            case model.usernameValidation.username of
                Just username ->
                    let
                        newProfile =
                            StudentProfile.setUserName model.profile username
                    in
                    ( SafeModel { model | profile = newProfile }
                    , putProfile model.session model.config newProfile
                    )

                Nothing ->
                    ( SafeModel model, Cmd.none )

        CancelUsernameUpdate ->
            ( toggleUsernameUpdate (SafeModel model), Cmd.none )

        Submitted (Ok studentProfile) ->
            ( SafeModel { model | profile = studentProfile, editing = Dict.fromList [] }, Cmd.none )

        Submitted (Err err) ->
            case err of
                Http.BadStatus resp ->
                    ( SafeModel model, Cmd.none )

                Http.BadBody _ ->
                    ( SafeModel model, Cmd.none )

                _ ->
                    ( SafeModel model, Cmd.none )

        SubmittedConsent (Ok resp) ->
            ( SafeModel { model | consentedToResearch = resp.consented }, Cmd.none )

        SubmittedConsent (Err err) ->
            case err of
                Http.BadStatus resp ->
                    ( SafeModel model, Cmd.none )

                Http.BadBody _ ->
                    ( SafeModel model, Cmd.none )

                _ ->
                    ( SafeModel model, Cmd.none )

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
    -> StudentProfile.StudentProfile
    -> Cmd Msg
putProfile session config profile =
    case StudentProfile.studentID profile of
        Just studentId ->
            Api.put
                (Endpoint.studentProfile (Config.restApiUrl config) studentId)
                (Session.cred session)
                (Http.jsonBody (profileEncoder profile))
                Submitted
                studentProfileDecoder

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
                SubmittedConsent
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
        ValidUsername
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


type alias StudentProfileParams =
    { id : Maybe Int
    , username : Maybe String
    , email : String
    , difficulty_preference : Maybe Text.TextDifficulty
    , difficulties : List Text.TextDifficulty
    , uris : StudentURIParams
    }


type alias StudentURIParams =
    { logout_uri : String
    , profile_uri : String
    }


studentProfileDecoder : Decoder StudentProfile.StudentProfile
studentProfileDecoder =
    Decode.map StudentProfile.initProfile studentProfileParamsDecoder


studentProfileParamsDecoder : Decoder StudentProfileParams
studentProfileParamsDecoder =
    Decode.succeed StudentProfileParams
        |> required "id" (Decode.nullable Decode.int)
        |> required "username" (Decode.nullable Decode.string)
        |> required "email" Decode.string
        |> required "difficultyPreference" (Decode.nullable Utils.stringTupleDecoder)
        |> required "difficulties" (Decode.list Utils.stringTupleDecoder)
        |> required "uris" studentProfileURIParamsDecoder


studentProfileURIParamsDecoder : Decoder StudentURIParams
studentProfileURIParamsDecoder =
    Decode.succeed StudentURIParams
        |> required "logout_uri" Decode.string
        |> required "profile_uri" Decode.string


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
            [ viewHeader (SafeModel model)
            , viewContent (SafeModel model)
            , Views.view_footer
            ]
        ]
    }


viewHeader : SafeModel -> Html Msg
viewHeader safeModel =
    Views.view_header
        (viewTopHeader safeModel)
        (viewLowerMenu safeModel)


viewTopHeader : SafeModel -> List (Html Msg)
viewTopHeader safeModel =
    [ div [ classList [ ( "menu_item", True ) ] ]
        [ a
            [ class "link"
            , href
                (Route.toString Route.Profile__Student)
            ]
            [ text "Profile" ]
        ]
    , div [ classList [ ( "menu_item", True ) ] ]
        [ a [ class "link", onClick Logout ]
            [ text "Logout" ]
        ]

    -- , div [] [ viewProfileHint safeModel ]
    ]


viewLowerMenu : SafeModel -> List (Html Msg)
viewLowerMenu (SafeModel model) =
    [ div
        [ classList
            [ ( "lower-menu-item", True )

            -- , ( "lower-menu-item-selected", Menu.Item.selected menu_item )
            ]
        ]
      <|
        viewSearchTextsHint
            (SafeModel model)
            ++ [ a
                    [ class "link"
                    , href (Route.toString Route.NotFound)
                    ]
                    [ text "Find a text to read" ]
               ]
    , div
        [ classList [ ( "lower-menu-item", True ) ] ]
        [ a
            [ class "link"
            , href (Route.toString Route.NotFound)
            ]
            [ text "Practice Flashcards" ]
        ]
    ]


viewContent : SafeModel -> Html Msg
viewContent (SafeModel model) =
    div [ classList [ ( "profile", True ) ] ]
        [ div [ classList [ ( "profile_items", True ) ] ]
            [ viewPreferredDifficulty (SafeModel model)
            , viewUsername (SafeModel model)
            , viewUserEmail (SafeModel model)
            , viewStudentPerformance (SafeModel model)
            , viewFeedbackLinks
            , viewFlashcards (SafeModel model)
            , viewResearchConsent (SafeModel model)
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
        [ Html.select [ onInput UpdateDifficulty ]
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
                    (StudentProfile.studentDifficulties model.profile)
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
            model.performanceReport
    in
    div [ class "performance" ] <|
        viewPerformanceHint (SafeModel model)
            ++ [ span [ class "profile_item_title" ] [ Html.text "My Performance: " ]
               , span [ class "profile_item_value" ]
                    [ div [ class "performance_report" ]
                        (performanceReportNode performanceReport.html)
                    ]
               , div [ class "performance_download_link" ]
                    [ Html.a [ attribute "href" performanceReport.pdf_link ]
                        [ Html.text "Download as PDF"
                        ]
                    ]
               ]


performanceReportNode : String -> List (Html msg)
performanceReportNode htmlString =
    case Html.Parser.run htmlString of
        Ok node ->
            node
                |> Html.Parser.Util.toVirtualDom

        Err err ->
            [ Html.text "Err processing performance report. Please contact us for help." ]


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
        , Html.a [ attribute "href" "https://sites.google.com/pdx.edu/star-russian/home" ]
            [ Html.text "here"
            ]
        ]



-- HINTS


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
    if model.welcome then
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
    if model.welcome then
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
    if model.welcome then
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
    if model.welcome then
        [ Help.View.view_hint_overlay hintAttributes
        ]

    else
        []


viewProfileHint : SafeModel -> Html Msg
viewProfileHint (SafeModel model) =
    let
        profileHelp =
            Help.profileHelp

        hintAttributes =
            { id = Help.popupToOverlayID profileHelp
            , visible = Help.isVisible model.help profileHelp
            , text = Help.helpMsg profileHelp
            , cancel_event = onClick (CloseHint profileHelp)
            , next_event = onClick NextHint
            , prev_event = onClick PreviousHint
            , addl_attributes = [ id (Help.helpID model.help profileHelp) ]
            , arrow_placement = ArrowUp ArrowRight
            }
    in
    if model.welcome then
        div []
            [ Help.View.view_hint_overlay hintAttributes
            ]

    else
        div [] []


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
save model shared =
    shared


load : Shared.Model -> SafeModel -> ( SafeModel, Cmd Msg )
load shared safeModel =
    ( safeModel, Cmd.none )


subscriptions : SafeModel -> Sub Msg
subscriptions (SafeModel model) =
    Sub.none
