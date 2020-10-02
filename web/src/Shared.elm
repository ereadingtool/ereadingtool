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
import Browser.Navigation exposing (Key)
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, href, id)
import Html.Events exposing (onClick, onInput)
import Http exposing (Error)
import Id exposing (Id)
import Json.Encode as Encode
import Role exposing (Role(..))
import Session exposing (Session)
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
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
    , authMessage : String
    }


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
    ( Model url key session config Profile.emptyProfile ""
    , case Session.viewer session of
        Just viewer ->
            case Viewer.role viewer of
                Student ->
                    Cmd.batch
                        [ requestStudentProfile session config (Viewer.id viewer)
                        , Browser.Navigation.replaceUrl key (Route.toString Route.Profile__Student)
                        ]

                Instructor ->
                    Cmd.batch
                        [ requestInstructorProfile session config (Viewer.id viewer)
                        , Browser.Navigation.replaceUrl key (Route.toString Route.Profile__Instructor)
                        ]

        Nothing ->
            Cmd.none
    )



-- UPDATE


type Msg
    = GotAuthResult (Result AuthError AuthSuccess)
    | GotSession Session
    | GotStudentProfile (Result Error StudentProfile)
    | GotInstructorProfile (Result Error InstructorProfile)
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
              }
            , case Session.viewer session of
                Just viewer ->
                    case Viewer.role viewer of
                        Student ->
                            Cmd.batch
                                [ requestStudentProfile session model.config (Viewer.id viewer)
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

        GotInstructorProfile (Ok instructorProfile) ->
            ( { model | profile = Profile.fromInstructorProfile instructorProfile }
            , Cmd.none
            )

        GotInstructorProfile (Err err) ->
            -- ( model
            ( { model | profile = Profile.fromInstructorProfile fakeInstructorProfile }
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
                    , div [ class "menu" ] <|
                        viewTopHeader (Viewer.role viewer) toMsg
                    ]
                , div [ id "lower-menu" ]
                    [ div [ id "lower-menu-items" ] <|
                        viewLowerMenu (Viewer.role viewer)
                    ]
                ]

            Nothing ->
                [ div [ id "header" ]
                    [ viewLogo model.session ]
                , div [ id "lower-menu" ] []
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
            [ attribute "src" "/public/img/star_logo.png"
            , id "logo"
            , attribute "alt" "Steps To Advanced Reading Logo"
            ]
            []
        ]


viewTopHeader : Role -> (Msg -> msg) -> List (Html msg)
viewTopHeader role toMsg =
    [ div [ classList [ ( "menu_item", True ) ] ]
        [ a
            [ class "link"
            , href <|
                case role of
                    Student ->
                        Route.toString Route.Profile__Student

                    Instructor ->
                        Route.toString Route.Profile__Instructor
            ]
            [ text "Profile" ]
        ]
    , div [ classList [ ( "menu_item", True ) ] ]
        [ a [ class "link", onClick (toMsg Logout) ]
            [ text "Logout" ]
        ]
    ]


viewLowerMenu : Role -> List (Html msg)
viewLowerMenu role =
    case role of
        Student ->
            [ div
                [ classList [ ( "lower-menu-item", True ) ] ]
                [ a
                    [ class "link"
                    , href (Route.toString Route.Text__Search)
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

        Instructor ->
            [ div
                [ classList [ ( "lower-menu-item", True ) ] ]
                [ a
                    [ class "link"
                    , href (Route.toString Route.Text__EditorSearch)
                    ]
                    [ text "Find a text to edit" ]
                ]
            , div
                [ classList [ ( "lower-menu-item", True ) ] ]
                [ a
                    [ class "link"
                    , href (Route.toString Route.Text__Search)
                    ]
                    [ text "Find a text to read" ]
                ]
            , div
                [ classList [ ( "lower-menu-item", True ) ] ]
                [ a
                    [ class "link"
                    , href (Route.toString Route.Text__Create)
                    ]
                    [ text "Create a new text" ]
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
