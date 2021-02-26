module Pages.Login.Student exposing
    ( Model
    , Msg
    , Params
    , page
    )

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (classList)
import Http exposing (..)
import Ports
import Role exposing (Role(..))
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import User.Login as Login exposing (LoginParams)
import Utils exposing (isValidEmail)


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



-- INIT


type alias Params =
    ()


type alias Model =
    { role : Role
    , loginParams : LoginParams
    , errors : Dict String String
    }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared { params } =
    ( { role = Student
      , loginParams = LoginParams "" "" "student"
      , errors = Dict.fromList []
      }
    , Cmd.batch
        [ Ports.clearInputText "email-input"
        , Ports.clearInputText "password-input"
        ]
    )



-- UPDATE


type Msg
    = SubmittedLogin
    | UpdateEmail String
    | UpdatePassword String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdatePassword password ->
            let
                loginParams =
                    model.loginParams
            in
            ( { model
                | loginParams = { loginParams | password = password }
              }
            , Cmd.none
            )

        UpdateEmail email ->
            let
                loginParams =
                    model.loginParams
            in
            ( { model
                | loginParams = { loginParams | username = email }
                , errors =
                    if isValidEmail email || (email == "") then
                        Dict.remove "email" model.errors

                    else
                        Dict.insert "email" "This email is invalid" model.errors
              }
            , Cmd.none
            )

        SubmittedLogin ->
            ( { model | errors = Dict.fromList [] }
            , Login.login model.loginParams
            )


view : Model -> Document Msg
view model =
    { title = "Student Login"
    , body =
        [ div []
            [ viewContent model
            ]
        ]
    }


viewContent : Model -> Html Msg
viewContent model =
    div [ classList [ ( "login", True ) ] ]
        [ Login.viewLoginForm
            { loginParams = model.loginParams
            , onEmailUpdate = UpdateEmail
            , onPasswordUpdate = UpdatePassword
            , onSubmittedForm = SubmittedLogin
            , signUpRoute = Route.Signup__Student
            , loginRole = "Student Login"
            , otherLoginRole = "content editor"
            , otherLoginRoute = Route.Login__Instructor
            , maybeHelpMessage =
                Just
                    """When signing in, please note that this website is not connected to your university’s user account.
                       If this is your first time using this website, please create a new account."""
            , errors = model.errors
            }
        ]



-- SHARED


save : Model -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( { model
        | errors =
            Dict.insert "all" shared.authMessage model.errors
      }
    , Cmd.none
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
