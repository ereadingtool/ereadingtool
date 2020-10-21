module Shared exposing
    ( Flags
    , Model
    , Msg
    , answerFeedbackCharacterLimit
    , difficulties
    , init
    , statuses
    , subscriptions
    , tags
    , update
    , view
    )

import Api exposing (AuthError, AuthSuccess)
import Api.Config as Config exposing (Config)
import Api.Endpoint as Endpoint
import Browser.Dom
import Browser.Navigation exposing (Key)
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, href, id)
import Html.Events exposing (onClick, onInput)
import Http exposing (Error)
import Id exposing (Id)
import Json.Decode as Decode
import Json.Encode as Encode
import Role exposing (Role(..))
import Session exposing (Session)
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Task
import Url exposing (Url)
import User.Instructor.Profile as InstructorProfile
    exposing
        ( InstructorProfile(..)
        , InstructorUsername(..)
        )
import User.Profile as Profile exposing (Profile)
import User.Student.Profile as StudentProfile
    exposing
        ( StudentProfile(..)
        , StudentURIs(..)
        )
import User.Student.Resource as StudentResource
import Viewer exposing (Viewer)



-- INIT


type alias Model =
    { url : Url
    , key : Key
    , session : Session
    , config : Config
    , profile : Profile
    , researchConsent : Bool
    , menuVisibility : MenuVisibility
    , authMessage : String
    }


type MenuVisibility
    = Visible
    | Hidden


type alias Flags =
    { maybeConfig : Maybe Config
    , maybeViewer : Maybe Viewer
    }


init : Flags -> Url -> Key -> ( Model, Cmd Msg )
init flags url key =
    let
        session =
            Session.fromViewer flags.maybeViewer

        config =
            Config.init flags.maybeConfig
    in
    ( Model url key session config Profile.emptyProfile False Hidden ""
    , case Session.viewer session of
        Just viewer ->
            case Viewer.role viewer of
                Student ->
                    if List.any (\path -> url.path == path) publicPaths then
                        Cmd.batch
                            [ requestStudentProfile session config (Viewer.id viewer)
                            , getResearchConsent session config (Viewer.id viewer)
                            , Browser.Navigation.replaceUrl key (Route.toString Route.Profile__Student)
                            ]

                    else
                        Cmd.batch
                            [ requestStudentProfile session config (Viewer.id viewer)
                            , getResearchConsent session config (Viewer.id viewer)
                            ]

                Instructor ->
                    if List.any (\path -> url.path == path) publicPaths then
                        Cmd.batch
                            [ requestInstructorProfile session config (Viewer.id viewer)
                            , Browser.Navigation.replaceUrl key (Route.toString Route.Profile__Instructor)
                            ]

                    else
                        requestInstructorProfile session config (Viewer.id viewer)

        Nothing ->
            Cmd.none
    )


publicPaths : List String
publicPaths =
    [ "/"
    , "/login/instructor"
    , "/signup/student"
    , "/signup/instructor"
    ]



-- UPDATE


type Msg
    = GotAuthResult (Result AuthError AuthSuccess)
    | GotSession Session
    | GotStudentProfile (Result Error StudentProfile)
    | GotResearchConsent (Result Error Bool)
    | GotInstructorProfile (Result Error InstructorProfile)
    | ToggleMenuVisibility
    | Logout


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotAuthResult (Ok authSuccess) ->
            ( { model | authMessage = Api.authSuccessMessage authSuccess }
            , Cmd.none
            )

        GotAuthResult (Err authError) ->
            ( { model | authMessage = Api.authErrorMessage authError }
            , Cmd.none
            )

        GotSession session ->
            ( { model
                | session = session
                , menuVisibility = Hidden
              }
            , case Session.viewer session of
                Just viewer ->
                    case Viewer.role viewer of
                        Student ->
                            Cmd.batch
                                [ requestStudentProfile session model.config (Viewer.id viewer)
                                , getResearchConsent session model.config (Viewer.id viewer)
                                , Browser.Navigation.replaceUrl model.key (Route.toString Route.Profile__Student)
                                ]

                        Instructor ->
                            Cmd.batch
                                [ requestInstructorProfile session model.config (Viewer.id viewer)
                                , Browser.Navigation.replaceUrl model.key (Route.toString Route.Profile__Instructor)
                                ]

                Nothing ->
                    Cmd.none
            )

        GotStudentProfile (Ok studentProfile) ->
            ( { model | profile = Profile.fromStudentProfile studentProfile }
            , Cmd.none
            )

        GotStudentProfile (Err err) ->
            ( model
            , Cmd.none
            )

        GotResearchConsent (Ok researchConsent) ->
            ( { model | researchConsent = researchConsent }
            , Cmd.none
            )

        GotResearchConsent (Err err) ->
            ( model
            , Cmd.none
            )

        GotInstructorProfile (Ok instructorProfile) ->
            ( { model | profile = Profile.fromInstructorProfile instructorProfile }
            , Cmd.none
            )

        GotInstructorProfile (Err err) ->
            -- ( model
            ( { model | profile = Profile.fromInstructorProfile fakeInstructorProfile }
            , Cmd.none
            )

        ToggleMenuVisibility ->
            ( case model.menuVisibility of
                Visible ->
                    { model | menuVisibility = Hidden }

                Hidden ->
                    { model | menuVisibility = Visible }
            , Cmd.none
            )

        Logout ->
            ( model
            , Api.logout ()
            )


fakeInstructorProfile : InstructorProfile
fakeInstructorProfile =
    InstructorProfile
        (Just 0)
        []
        True
        (Just [])
        (InstructorProfile.InstructorUsername "fakeInstructor")
        (InstructorProfile.initProfileURIs
            { logout_uri = "fakeLogoutURI"
            , profile_uri = "fakeProfileURI"
            }
        )


requestStudentProfile : Session -> Config -> Id -> Cmd Msg
requestStudentProfile session config id =
    Api.get
        (Endpoint.studentProfile
            (Config.restApiUrl config)
            (Id.id id)
        )
        (Session.cred session)
        GotStudentProfile
        StudentProfile.decoder


getResearchConsent :
    Session
    -> Config
    -> Id
    -> Cmd Msg
getResearchConsent session config id =
    Api.get
        (Endpoint.consentToResearch (Config.restApiUrl config) (Id.id id))
        (Session.cred session)
        GotResearchConsent
        (Decode.field "consented" Decode.bool)


requestInstructorProfile : Session -> Config -> Id -> Cmd Msg
requestInstructorProfile session config id =
    Api.get
        (Endpoint.instructorProfile
            (Config.restApiUrl config)
            (Id.id id)
        )
        (Session.cred session)
        GotInstructorProfile
        InstructorProfile.decoder


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Session.changes GotSession
        , Api.authResult (\authMessage -> GotAuthResult authMessage)
        ]



-- VIEW


view :
    { page : Document msg, toMsg : Msg -> msg }
    -> Model
    -> Document msg
view { page, toMsg } model =
    { title = page.title
    , body =
        [ div [ class "layout" ]
            [ viewHeader model toMsg
            , div [ class "page" ] page.body
            ]
        ]
    }


viewHeader : Model -> (Msg -> msg) -> Html msg
viewHeader model toMsg =
    div [] <|
        case Session.viewer model.session of
            Just viewer ->
                [ div [ id "header" ]
                    [ viewLogo model.session
                    , viewMenuIcon toMsg
                    , div
                        [ case model.menuVisibility of
                            Visible ->
                                class "content-menu"

                            Hidden ->
                                classList [ ( "content-menu", True ), ( "hidden-menu", True ) ]
                        ]
                      <|
                        viewContentHeader (Viewer.role viewer)
                    , div
                        [ case model.menuVisibility of
                            Visible ->
                                class "profile-menu"

                            Hidden ->
                                classList [ ( "profile-menu", True ), ( "hidden-menu", True ) ]
                        ]
                      <|
                        viewProfileHeader (Viewer.role viewer) toMsg
                    ]
                ]

            Nothing ->
                [ div [ id "header" ]
                    [ viewLogo model.session
                    , viewMenuIcon toMsg
                    ]
                ]


viewMenuIcon : (Msg -> msg) -> Html msg
viewMenuIcon toMsg =
    div
        [ class "menu-icon"
        ]
        [ img
            [ attribute "src" "/public/img/menu.svg"
            , onClick (toMsg ToggleMenuVisibility)
            ]
            []
        ]


viewLogo : Session -> Html msg
viewLogo session =
    a
        [ href <|
            case Session.viewer session of
                Just viewer ->
                    case Viewer.role viewer of
                        Student ->
                            Route.toString Route.Profile__Student

                        Instructor ->
                            Route.toString Route.Profile__Instructor

                Nothing ->
                    Route.toString Route.Top
        ]
        [ Html.img
            [ attribute "src" "/public/img/star_logo.svg"
            , id "logo"
            , attribute "alt" "Steps To Advanced Reading Logo"
            ]
            []
        ]


viewContentHeader : Role -> List (Html msg)
viewContentHeader role =
    case role of
        Student ->
            [ div
                [ class "nav-item" ]
                [ a
                    [ class "nav-link"
                    , href (Route.toString Route.Text__Search)
                    ]
                    [ text "Texts" ]
                ]
            , div
                [ class "nav-item" ]
                [ a
                    [ class "nav-link"
                    , href (Route.toString Route.Flashcards__Student)
                    ]
                    [ text "Flashcards" ]
                ]
            ]

        Instructor ->
            [ div
                [ class "nav-item" ]
                [ a
                    [ class "nav-link"
                    , href (Route.toString Route.Text__Search)
                    ]
                    [ text "Texts" ]
                ]
            , div
                [ class "nav-item" ]
                [ a
                    [ class "nav-link"
                    , href (Route.toString Route.Text__EditorSearch)
                    ]
                    [ text "Edit" ]
                ]
            , div
                [ class "nav-item" ]
                [ a
                    [ class "nav-link"
                    , href (Route.toString Route.Text__Create)
                    ]
                    [ text "Create" ]
                ]
            ]


viewProfileHeader : Role -> (Msg -> msg) -> List (Html msg)
viewProfileHeader role toMsg =
    [ div [ class "nav-item" ]
        [ a
            [ class "nav-link"
            , href <|
                case role of
                    Student ->
                        Route.toString Route.Profile__Student

                    Instructor ->
                        Route.toString Route.Profile__Instructor
            ]
            [ text "Profile" ]
        ]
    , div [ class "nav-item " ]
        [ a [ onClick (toMsg Logout), class "nav-link" ]
            [ text "Logout" ]
        ]
    ]



-- DATA


difficulties : List ( String, String )
difficulties =
    [ ( "intermediate_mid", "Intermediate-Mid" )
    , ( "intermediate_high", "Intermediate-High" )
    , ( "advanced_low", "Advanced-Low" )
    , ( "advanced_mid", "Advanced-Mid" )
    ]


tags : List String
tags =
    [ "Culture"
    , "Music"
    , "Film"
    , "Literary Arts"
    , "Visual Arts"
    , "Sports"
    , "Internal Affairs"
    , "History"
    , "Biography"
    , "News Briefs"
    , "Economics/Business"
    , "Medicine/Health Care"
    , "Science/Technology"
    , "Human Interest"
    , "Society and Societal Trends"
    , "International Relations"
    , "Public Policy"
    , "Other"
    , "Kazakhstan"
    ]


statuses : List ( String, String )
statuses =
    [ ( "unread", "Unread" )
    , ( "in_progress", "In Progress" )
    , ( "read", "Read" )
    ]


answerFeedbackCharacterLimit : Int
answerFeedbackCharacterLimit =
    2048
