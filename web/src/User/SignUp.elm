module User.SignUp exposing
    ( viewEmailInput
    , viewInternalErrorMessage
    , viewPasswordInputs
    , viewValidationError
    )

import Dict exposing (Dict)
import Html exposing (Html, div)
import Html.Attributes exposing (attribute, class, classList)
import Html.Events exposing (onClick, onInput)
import Utils exposing (isValidEmail)


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
                []
    in
    [ viewSignupLabel (Html.text "Email Address")
    , Html.input ([ attribute "size" "25", onInput onEmailInput ] ++ errorClass) []
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
                        []
                   )
                ++ (if options.showPasswords then
                        [ attribute "type" "text" ]

                    else
                        [ attribute "type" "password" ]
                   )
    in
    [ viewSignupLabel
        (Html.span []
            [ Html.text "Password "
            , Html.span [ onClick options.onShowPasswordToggle, attribute "class" "cursor" ]
                [ Html.text "(show)" ]
            ]
        )
    , Html.input (onInput options.onPasswordInput :: attributes) []
    , passwordErrorMessage
    , viewSignupLabel (Html.text "Confirm Password")
    , Html.input (onInput options.onConfirmPasswordInput :: attributes) []
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
