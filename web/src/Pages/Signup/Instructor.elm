module Pages.Signup.Instructor exposing
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
import Html exposing (Html, div)
import Html.Attributes exposing (attribute, class, classList)
import Html.Events exposing (onClick, onInput)
import Http exposing (..)
import Http.Detailed
import Json.Decode
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import User.SignUp as SignUp
import Utils exposing (isValidEmail)
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


type alias SignUpParams =
    { email : String
    , password : String
    , confirmPassword : String
    , inviteCode : String
    }


type alias SignUpResponse =
    { id : Int }



-- INIT


type alias Params =
    ()


type alias Model =
    { session : Session
    , config : Config
    , navKey : Key
    , signupParams : SignUpParams
    , showPasswords : Bool
    , errors : Dict String String
    }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared { params } =
    ( { session = shared.session
      , config = shared.config
      , navKey = shared.key
      , signupParams =
            { email = ""
            , password = ""
            , confirmPassword = ""
            , inviteCode = ""
            }
      , showPasswords = False
      , errors = Dict.empty
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = ToggleShowPassword
    | UpdateEmail String
    | UpdatePassword String
    | UpdateConfirmPassword String
    | UpdateInviteCode String
    | SubmittedForm
    | CompletedSignup (Result (Http.Detailed.Error String) ( Http.Metadata, SignUpResponse ))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleShowPassword ->
            ( { model | showPasswords = not model.showPasswords }
            , Cmd.none
            )

        UpdatePassword password ->
            ( model
                |> updateSignupParams (\signupParams -> { signupParams | password = password })
            , Cmd.none
            )

        UpdateConfirmPassword confirmPassword ->
            ( { model
                | errors = validatePasswordsMatch model.signupParams.password confirmPassword model.errors
              }
                |> updateSignupParams (\signupParams -> { signupParams | confirmPassword = confirmPassword })
            , Cmd.none
            )

        UpdateEmail email ->
            ( { model
                | errors = validateEmail email model.errors
              }
                |> updateSignupParams (\signupParams -> { signupParams | email = email })
            , Cmd.none
            )

        UpdateInviteCode inviteCode ->
            ( { model
                | errors = validateInviteCode inviteCode model.errors
              }
                |> updateSignupParams (\signupParams -> { signupParams | inviteCode = inviteCode })
            , Cmd.none
            )

        SubmittedForm ->
            ( { model | errors = Dict.empty }
            , postSignup model.session model.config model.signupParams
            )

        CompletedSignup (Ok resp) ->
            ( model
            , Browser.Navigation.replaceUrl model.navKey (Route.toString Route.Login__Instructor)
            )

        CompletedSignup (Err error) ->
            case error of
                Http.Detailed.BadStatus metadata body ->
                    ( { model | errors = errorBodyToDict body }
                    , Cmd.none
                    )

                _ ->
                    ( { model
                        | errors =
                            Dict.fromList [ ( "internal", "An internal error occured. Please contact the developers." ) ]
                      }
                    , Cmd.none
                    )


updateSignupParams : (SignUpParams -> SignUpParams) -> Model -> Model
updateSignupParams transform model =
    { model | signupParams = transform model.signupParams }


validateEmail : String -> Dict String String -> Dict String String
validateEmail email errors =
    if isValidEmail email || (email == "") then
        Dict.remove "email" errors

    else
        Dict.insert "email" "This e-mail is invalid" errors


validatePasswordsMatch : String -> String -> Dict String String -> Dict String String
validatePasswordsMatch password confirmPassword errors =
    if confirmPassword == password then
        Dict.remove "password" (Dict.remove "confirm_password" errors)

    else
        Dict.insert "confirm_password" "Passwords don't match." errors


validateInviteCode : String -> Dict String String -> Dict String String
validateInviteCode inviteCode errors =
    let
        ( validInviteCode, inviteCodeError ) =
            validateInviteCodeLength inviteCode
    in
    if validInviteCode || (inviteCode == "") then
        Dict.remove "invite_code" errors

    else
        Dict.insert
            "invite_code"
            ("This invite code is " ++ Maybe.withDefault "" inviteCodeError ++ ".")
            errors


validateInviteCodeLength : String -> ( Bool, Maybe String )
validateInviteCodeLength inviteCode =
    if String.length inviteCode > 64 then
        ( False, Just "too long" )

    else if String.length inviteCode < 64 then
        ( False, Just "too short" )

    else
        ( True, Nothing )


postSignup : Session -> Config -> SignUpParams -> Cmd Msg
postSignup session config signupParams =
    let
        encodedSignupParams =
            signUpEncoder signupParams
    in
    Api.postDetailed
        (Endpoint.instructorSignup (Config.restApiUrl config))
        (Session.cred session)
        (Http.jsonBody encodedSignupParams)
        CompletedSignup
        signUpResponseDecoder


signUpEncoder : SignUpParams -> Encode.Value
signUpEncoder signupParams =
    Encode.object
        [ ( "email", Encode.string signupParams.email )
        , ( "password", Encode.string signupParams.password )
        , ( "confirm_password", Encode.string signupParams.confirmPassword )
        , ( "invite_code", Encode.string signupParams.inviteCode )
        ]


signUpResponseDecoder : Json.Decode.Decoder SignUpResponse
signUpResponseDecoder =
    Json.Decode.succeed SignUpResponse
        |> required "id" Json.Decode.int


errorBodyToDict : String -> Dict String String
errorBodyToDict body =
    case Json.Decode.decodeString (Json.Decode.dict Json.Decode.string) body of
        Ok dict ->
            dict

        Err err ->
            Dict.fromList [ ( "internal", "An internal error occured. Please contact the developers." ) ]



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Instructor Signup"
    , body =
        [ div []
            [ div [ classList [ ( "signup", True ) ] ]
                [ div [ classList [ ( "signup_box", True ) ] ] <|
                    [ div [ class "signup_title" ] [ Html.text "Instructor Signup" ] ]
                        ++ SignUp.viewEmailInput
                            { errors = model.errors
                            , onEmailInput = UpdateEmail
                            }
                        ++ SignUp.viewPasswordInputs
                            { showPasswords = model.showPasswords
                            , errors = model.errors
                            , onShowPasswordToggle = ToggleShowPassword
                            , onPasswordInput = UpdatePassword
                            , onConfirmPasswordInput = UpdateConfirmPassword
                            }
                        ++ viewInviteCodeInput model
                        ++ SignUp.viewInternalErrorMessage model.errors
                        ++ [ Html.div
                                [ attribute "class" "signup_label" ]
                                [ if
                                    not (Dict.isEmpty model.errors)
                                        || String.isEmpty model.signupParams.email
                                        || String.isEmpty model.signupParams.password
                                        || String.isEmpty model.signupParams.confirmPassword
                                        || String.isEmpty model.signupParams.inviteCode
                                  then
                                    div [ class "button", class "disabled" ]
                                        [ div [ class "signup_submit" ] [ Html.span [] [ Html.text "Sign Up" ] ]
                                        ]

                                  else
                                    div [ class "button", onClick SubmittedForm, class "cursor" ]
                                        [ div [ class "signup_submit" ] [ Html.span [] [ Html.text "Sign Up" ] ]
                                        ]
                                ]
                           ]
                ]
            , Views.view_footer
            ]
        ]
    }


viewInviteCodeInput : Model -> List (Html Msg)
viewInviteCodeInput model =
    let
        errorMessage =
            if Dict.member "invite_code" model.errors then
                [ SignUp.viewValidationError
                    (Html.em [] [ Html.text (Maybe.withDefault "" (Dict.get "invite_code" model.errors)) ])
                ]

            else
                []

        errorClass =
            if Dict.member "invite_code" model.errors then
                [ attribute "class" "input_error" ]

            else
                []
    in
    [ Html.div [ class "input-container" ]
        [ Html.input
            ([ class "password-input", attribute "placeholder" "Invite Code", attribute "size" "25", onInput UpdateInviteCode ] ++ errorClass)
            []
        ]
    ]
        ++ errorMessage



-- SHARED


save : Model -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
