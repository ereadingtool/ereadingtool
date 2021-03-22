module User.Login exposing (LoginParams, login, viewLoginForm)

import Api
import Dict exposing (Dict)
import Html exposing (Html, div, span, text)
import Html.Attributes exposing (attribute, class, classList, id)
import Html.Events exposing (onClick, onInput)
import Http exposing (..)
import Json.Encode as Encode
import Spa.Generated.Route as Route exposing (Route)
import Utils


type alias LoginParams =
    { username : String
    , password : String
    , role : String
    }



-- -- AUTH


login : LoginParams -> Cmd msg
login loginParams =
    let
        creds =
            Encode.object
                [ ( "username", Encode.string loginParams.username )
                , ( "password", Encode.string loginParams.password )
                , ( "role", Encode.string loginParams.role )
                ]
    in
    Api.login creds



-- VIEW


viewLoginForm :
    { loginParams : LoginParams
    , onEmailUpdate : String -> msg
    , onPasswordUpdate : String -> msg
    , onSubmittedForm : msg
    , signUpRoute : Route
    , loginRole : String
    , otherLoginRole : String
    , otherLoginRoute : Route
    , maybeHelpMessage : Maybe String
    , errors : Dict String String
    }
    -> Html msg
viewLoginForm loginOptions =
    div [ classList [ ( "login_box", True ) ] ] <|
        viewLoginFormTitle loginOptions.loginRole
            ++ viewEmailInput
                { onEmailUpdate = loginOptions.onEmailUpdate
                , errors = loginOptions.errors
                }
            ++ viewPasswordInput
                { onPasswordUpdate = loginOptions.onPasswordUpdate
                , onSubmittedForm = loginOptions.onSubmittedForm
                , errors = loginOptions.errors
                }
            ++ viewLoginOptions
                { signUpRoute = loginOptions.signUpRoute
                , otherLoginRole = loginOptions.otherLoginRole
                , otherLoginRoute = loginOptions.otherLoginRoute
                }
            ++ viewSubmit
                { loginParams = loginOptions.loginParams
                , onSubmittedForm = loginOptions.onSubmittedForm
                }
            ++ viewHelpMessages loginOptions.maybeHelpMessage
            ++ viewLinks
            ++ viewErrors loginOptions.errors


viewLoginFormTitle : String -> List (Html msg)
viewLoginFormTitle loginRole =
    [ div [ class "login_role" ] [ Html.text loginRole ] ]


viewEmailInput :
    { onEmailUpdate : String -> msg
    , errors : Dict String String
    }
    -> List (Html msg)
viewEmailInput { onEmailUpdate, errors } =
    let
        emailErrorClass =
            if Dict.member "email" errors then
                [ attribute "class" "input_error" ]

            else
                [ attribute "class" "input_valid" ]
    in
    [ div [ class "input-container" ]
        [ Html.input
            ([ id "email-input"
             , attribute "size" "25"
             , attribute "placeholder" "Email Address"
             , onInput onEmailUpdate
             ]
                ++ emailErrorClass
            )
            []
        ]
    , case Dict.get "email" errors of
        Just errorMsg ->
            div [] [ Html.em [] [ Html.text errorMsg ] ]

        Nothing ->
            Html.text ""
    ]


viewPasswordInput :
    { onPasswordUpdate : String -> msg
    , onSubmittedForm : msg
    , errors : Dict String String
    }
    -> List (Html msg)
viewPasswordInput { onPasswordUpdate, onSubmittedForm, errors } =
    let
        passwordErrorClass =
            if Dict.member "password" errors then
                [ attribute "class" "input_error" ]

            else
                []

        passwordErrorMessage =
            case Dict.get "password" errors of
                Just errorMessage ->
                    div [] [ Html.em [] [ Html.text errorMessage ] ]

                Nothing ->
                    Html.text ""
    in
    [ div [ class "input-container" ]
        [ Html.input
            ([ id "password-input"
             , attribute "size" "35"
             , attribute "type" "password"
             , attribute "placeholder" "Password"
             , onInput onPasswordUpdate
             , Utils.onEnterUp onSubmittedForm
             ]
                ++ passwordErrorClass
            )
            []
        ]
    , passwordErrorMessage
    ]


viewLoginOptions :
    { signUpRoute : Route
    , otherLoginRoute : Route
    , otherLoginRole : String
    }
    -> List (Html msg)
viewLoginOptions options =
    [ span [ class "login_options" ]
        [ viewNotRegistered options.signUpRoute
        , viewForgotPassword
        , viewOtherLoginOption
            { otherRole = options.otherLoginRole, otherRoute = options.otherLoginRoute }
        ]
    ]


viewNotRegistered : Route -> Html msg
viewNotRegistered signUpRoute =
    div []
        [ Html.text "Not registered? "
        , Html.a [ attribute "href" (Route.toString signUpRoute) ]
            [ span [ attribute "class" "cursor" ] [ Html.text "Sign Up" ]
            ]
        ]


viewForgotPassword : Html msg
viewForgotPassword =
    div []
        [ Html.text "Forgot Password? "
        , Html.a [ attribute "href" (Route.toString Route.User__ForgotPassword) ]
            [ span [ attribute "class" "cursor" ]
                [ Html.text "Reset Password"
                ]
            ]
        ]


viewOtherLoginOption :
    { otherRole : String, otherRoute : Route }
    -> Html msg
viewOtherLoginOption { otherRole, otherRoute } =
    div []
        [ Html.text ("Are you a " ++ otherRole ++ "? ")
        , Html.a [ attribute "href" (Route.toString otherRoute) ]
            [ span [ attribute "class" "cursor" ]
                [ Html.text ("Login as a " ++ otherRole)
                ]
            ]
        ]


viewSubmit :
    { loginParams : LoginParams
    , onSubmittedForm : msg
    }
    -> List (Html msg)
viewSubmit options =
    if
        String.isEmpty options.loginParams.username
            || String.isEmpty options.loginParams.password
    then
        [ div [ class "button", class "disabled" ]
            [ div [ class "login_submit" ] [ Html.span [] [ Html.text "Login" ] ]
            ]
        ]

    else
        [ div [ class "button", onClick options.onSubmittedForm, class "cursor" ]
            [ div [ class "login_submit" ] [ span [] [ Html.text "Login" ] ] ]
        ]


viewHelpMessages : Maybe String -> List (Html msg)
viewHelpMessages maybeHelpMessage =
    case maybeHelpMessage of
        Just message ->
            [ div [ class "help_msgs" ]
                [ Html.text message
                ]
            ]

        Nothing ->
            []


viewLinks : List (Html msg)
viewLinks =
    [ div [ id "acknowledgements-and-about" ]
        [ div []
            [ Html.a [ attribute "href" (Route.toString Route.About) ]
                [ text "About This Website"
                ]
            ]
        , div []
            [ Html.a [ attribute "href" (Route.toString Route.Acknowledgments) ]
                [ text "Acknowledgements"
                ]
            ]
        ]
    ]


viewErrors : Dict String String -> List (Html msg)
viewErrors errors =
    case Dict.get "all" errors of
        Just allErrors ->
            [ div [] [ span [ attribute "class" "errors" ] [ Html.em [] [ Html.text <| allErrors ] ] ] ]

        Nothing ->
            [ span [ attribute "class" "errors" ] [] ]
