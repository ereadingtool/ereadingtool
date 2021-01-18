module User.SignUp exposing
    ( viewEmailInput
    , viewInternalErrorMessage
    , viewPasswordInputs
    , viewValidationError
    )

import Dict exposing (Dict)
import Html exposing (Html, div)
import Html.Attributes exposing (attribute, class, classList, id)
import Html.Events exposing (onClick, onInput)
import Menu.Msg as MenuMsg
import Utils exposing (isValidEmail)
import Views


viewEmailInput :
    { errors : Dict String String
    , onEmailInput : String -> msg
    }
    -> List (Html msg)
viewEmailInput { errors, onEmailInput } =
    let
        errorMessage =
            case Dict.get "email" errors of
                Just errMsg ->
                    [ viewValidationError (Html.em [] [ Html.text errMsg ]) ]

                Nothing ->
                    []

        errorClass =
            if Dict.member "email" errors then
                [ attribute "class" "input_error" ]

            else
                [ attribute "class" "input_valid" ]
    in
    [ div [ class "input-container" ] [
        div [ class "email-input" ] [
            Html.input ([ class "email-input", onInput onEmailInput, attribute "size" "25", attribute "placeholder" "Email Address" ] ++ errorClass) []
            ]
        ]
    ]
        ++ errorMessage


viewPasswordInputs :
    { showPasswords : Bool
    , errors : Dict String String
    , onShowPasswordToggle : msg
    , onPasswordInput : String -> msg
    , onConfirmPasswordInput : String -> msg
    }
    -> List (Html msg)
viewPasswordInputs options =
    let
        confirmErrorMessage =
            case Dict.get "confirm_password" options.errors of
                Just errorMessage ->
                    viewValidationError (Html.em [] [ Html.text errorMessage ])

                Nothing ->
                    Html.text ""

        passwordErrorMessage =
            case Dict.get "password" options.errors of
                Just errorMessage ->
                    viewValidationError (Html.em [] [ Html.text errorMessage ])

                Nothing ->
                    Html.text ""

        attributes =
            [ attribute "size" "35" ]
                ++ (if
                        Dict.member "confirm_password" options.errors
                            || Dict.member "password" options.errors
                    then
                        [ attribute "class" "input_error" ]

                    else
                        [ attribute "class" "input_valid"]
                   )
                ++ (if options.showPasswords then
                        [ attribute "type" "text" ]

                    else
                        [ attribute "type" "password" ]
                   )
    in
    [ div [ class "input-container" ] [
        Html.input (onInput options.onPasswordInput :: attributes ++ [ attribute "placeholder" "Password", class "email-input" ]) []
        , (if options.showPasswords then
            Html.span [ onClick options.onShowPasswordToggle, id "show-password-button" ]
                [ Html.img [ id "visibility-image", attribute "src" "/public/img/visibility_off-24px.svg" ] [] ]
            else
            Html.span [ onClick options.onShowPasswordToggle, id "show-password-button" ]
                [ Html.img [ id "visibility-image", attribute "src" "/public/img/visibility-24px.svg" ] [] ]
        )
        ]
    , passwordErrorMessage
    , div [ class "input-container" ][ 
        Html.input (onInput options.onConfirmPasswordInput :: attributes ++ [ attribute "placeholder" "Confirm Password" , class "password-input" ]) []
    ]
    , confirmErrorMessage
    ]


viewInternalErrorMessage : Dict String String -> List (Html msg)
viewInternalErrorMessage errors =
    case Dict.get "internal" errors of
        Just errorMessage ->
            [ viewValidationError (Html.em [] [ Html.text errorMessage ]) ]

        Nothing ->
            []


viewSignupLabel : Html msg -> Html msg
viewSignupLabel html =
    Html.div [ attribute "class" "signup_label" ] [ html ]


viewValidationError : Html msg -> Html msg
viewValidationError html =
    div [ class "validation-error" ]
        [ html
        ]
