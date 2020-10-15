module Pages.Signup.Student exposing
    ( Model
    , Msg
    , Params
    , page
    )

import Api exposing (post)
import Api.Config as Config exposing (Config)
import Api.Endpoint as Endpoint
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Html exposing (Html, div, span)
import Html.Attributes exposing (attribute, class, classList)
import Html.Events exposing (onClick, onInput)
import Http exposing (..)
import Json.Decode
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import Menu.Msg as MenuMsg
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Text.Model exposing (TextDifficulty)
import User.SignUp as SignUp
import Views


page : Page Params Model Msg
page =
    Page.application
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , save = save
        , load = load
        }


type alias SignUpResp =
    { id : SignUp.UserID
    , redirect : SignUp.RedirectURI
    }


type alias SignUpParams =
    { email : String
    , password : String
    , confirm_password : String
    , difficulty : String
    }



-- INIT


type alias Params =
    ()


type alias Model =
    { session : Session
    , config : Config
    , navKey : Key
    , difficulties : List ( String, String )
    , signup_params : SignUpParams
    , show_passwords : Bool
    , errors : Dict String String
    }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared { params } =
    ( { session = shared.session
      , config = shared.config
      , navKey = shared.key
      , difficulties = Shared.difficulties
      , signup_params =
            { email = ""
            , password = ""
            , confirm_password = ""
            , difficulty =
                case List.head Shared.difficulties of
                    Just ( difficultyKey, difficultyName ) ->
                        difficultyKey

                    _ ->
                        ""
            }
      , show_passwords = False
      , errors = Dict.fromList []
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = ToggleShowPassword
    | UpdateEmail String
    | UpdatePassword String
    | UpdateConfirmPassword String
    | UpdateDifficulty String
    | Submitted (Result Http.Error SignUpResp)
    | Submit
    | Logout MenuMsg.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleShowPassword ->
            ( SignUp.toggle_show_password model, Cmd.none )

        UpdatePassword password ->
            ( SignUp.update_password model password, Cmd.none )

        UpdateConfirmPassword confirmPassword ->
            ( SignUp.update_confirm_password model confirmPassword, Cmd.none )

        UpdateEmail addr ->
            ( SignUp.update_email model addr, Cmd.none )

        UpdateDifficulty difficulty ->
            let
                signupParams =
                    model.signup_params
            in
            ( { model | signup_params = { signupParams | difficulty = difficulty } }, Cmd.none )

        Submit ->
            ( SignUp.submit model, postSignup model.session model.config model.signup_params )

        Submitted (Ok resp) ->
            ( model
            , Browser.Navigation.replaceUrl model.navKey (Route.toString Route.Top)
            )

        Submitted (Err error) ->
            let
                dbg =
                    Debug.log "errors" error
            in
            case error of
                Http.BadStatus resp ->
                    ( model, Cmd.none )

                Http.BadBody _ ->
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Logout _ ->
            ( model, Cmd.none )


postSignup : Session -> Config -> SignUpParams -> Cmd Msg
postSignup session config signup_params =
    let
        encodedSignupParams =
            signUpEncoder signup_params
    in
    Api.post
        (Endpoint.studentSignup (Config.restApiUrl config))
        (Session.cred session)
        (Http.jsonBody encodedSignupParams)
        Submitted
        signUpRespDecoder


signUpEncoder : SignUpParams -> Encode.Value
signUpEncoder signup_params =
    Encode.object
        [ ( "email", Encode.string signup_params.email )
        , ( "password", Encode.string signup_params.password )
        , ( "confirm_password", Encode.string signup_params.confirm_password )
        , ( "difficulty", Encode.string signup_params.difficulty )
        ]


signUpRespDecoder : Json.Decode.Decoder SignUpResp
signUpRespDecoder =
    Json.Decode.succeed SignUpResp
        |> required "id" (Json.Decode.map SignUp.UserID Json.Decode.int)
        |> required "redirect" (Json.Decode.map (SignUp.URI >> SignUp.RedirectURI) Json.Decode.string)



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Student Signup"
    , body =
        [ div []
            [ viewContent model
            , Views.view_footer
            ]
        ]
    }


viewContent : Model -> Html Msg
viewContent model =
    div [ classList [ ( "signup", True ) ] ]
        [ div [ class "signup_title" ]
            [ Html.text "Student Signup"
            ]
        , viewStudentWelcomeMsg
        , div [ classList [ ( "signup_box", True ) ] ] <|
            SignUp.view_email_input UpdateEmail model
                ++ SignUp.view_password_input ( ToggleShowPassword, UpdatePassword, UpdateConfirmPassword ) model
                ++ viewDifficultyChoices model
                ++ [ Html.div
                        [ attribute "class" "signup_label" ]
                        [ if
                            not (Dict.isEmpty model.errors)
                                || String.isEmpty model.signup_params.email
                                || String.isEmpty model.signup_params.password
                                || String.isEmpty model.signup_params.confirm_password
                          then
                            div [ class "button", class "disabled" ]
                                [ div [ class "signup_submit" ] [ Html.span [] [ Html.text "Sign Up" ] ]
                                ]

                          else
                            div [ class "button", onClick Submit, class "cursor" ]
                                [ div [ class "signup_submit" ] [ Html.span [] [ Html.text "Sign Up" ] ]
                                ]
                        ]
                   ]
        ]


viewStudentWelcomeMsg : Html Msg
viewStudentWelcomeMsg =
    let
        welcomeTitle =
            """Welcome to The Language Flagship’s Steps To Advanced Reading (STAR) website."""
    in
    div [ class "welcome_msg" ]
        [ span [ class "headline" ] [ Html.text welcomeTitle ]
        , div [ class "welcome-msg-text" ]
            [ Html.p []
                [ Html.text
                    """The purpose of this site is to help students improve their reading proficiency in Flagship
            language that they are studying. This site includes a wide range of texts at different proficiency levels.
            You will select texts to read by proficiency level and by topic."""
                ]
            , Html.p []
                [ Html.text
                    """Before reading the Russian texts, you will get a brief contextualizing message in English.
            Then you will see the first part of the text followed by comprehension questions. Once you’ve read the text
            and selected the best answer, you will get feedback telling you if your choice is correct, and why or why
            not."""
                ]
            , Html.p []
                [ Html.text
                    """The format of this site resembles the Flagship proficiency tests, and our goal is to
            help you build your reading skills for those tests. Any particular reading should take you between 5-15
            minutes to complete, and we envision that you can use these texts on the go, when commuting, when waiting
            for a bus, etc.  You can come back to texts at any time.  If this is your first time using the website,
            pop-up boxes will help you learn how to use the site."""
                ]
            ]
        ]


viewDifficultyChoices : Model -> List (Html Msg)
viewDifficultyChoices model =
    [ SignUp.signupLabel (Html.text "Choose a preferred difficulty:")
    , Html.select
        [ onInput UpdateDifficulty
        ]
        [ Html.optgroup []
            (List.map
                (\( k, v ) ->
                    Html.option
                        (attribute "value" k
                            :: (if v == model.signup_params.difficulty then
                                    [ attribute "selected" "" ]

                                else
                                    []
                               )
                        )
                        [ Html.text v ]
                )
                model.difficulties
            )
        ]
    ]



-- SHARED


save : Model -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
